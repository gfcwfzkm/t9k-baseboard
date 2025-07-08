-- Dependency: src/alu.vhdl, src/barrel_shifter.vhdl, src/condition.vhdl, src/execute.vhdl
-- TEROSHDL Documentation:
--! @title Execute Unit Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 07.07.2025
--! @brief Testbench for the execute unit
--!
--! This testbench verifies the functionality of the execute unit.
--! It includes manual tests for each instruction type and ALU operation,
--! followed by a large number of random tests to ensure robustness.
--! The testbench checks the results against expected values and reports any discrepancies.
--!
--! The amount of random tests can be configured by changing the `RANDOM_TESTS` constant.
--! At the end, it reports the number of errors and the counts of each instruction type and ALU operation tested.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;
use std.textio.all;

entity tb_execute is
end entity;

architecture tb of tb_execute is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal instruction_type : std_logic_vector(1 downto 0);
    signal alu_op          : std_logic_vector(2 downto 0);
    signal jump_condition  : std_logic_vector(2 downto 0);
    signal dst_reg_i       : std_logic_vector(2 downto 0);
    signal alu_operand_a   : std_logic_vector(7 downto 0);
    signal source_register : std_logic_vector(7 downto 0);
    signal immediate_value : std_logic_vector(5 downto 0);
    signal dst_reg_o       : std_logic_vector(2 downto 0);
    signal result_register : std_logic_vector(7 downto 0);
    signal condition_result : std_logic;
    
    -- Test control
    constant RANDOM_TESTS  : integer := 50000;

    --! Function to calculate the expected output of the barrel shifter
    function expected_shift (
        input_vec : std_logic_vector(7 downto 0);
        shift : integer
    ) return std_logic_vector is
        constant len : natural := input_vec'length;
        variable temp : std_logic_vector(len-1 downto 0);
        variable input_vector : std_logic_vector(len-1 downto 0) := input_vec;
        variable abs_shift : natural;
    begin
        abs_shift := abs(shift) mod 8;
    
        temp := (others => '0');  -- Default to zero vector
        if shift >= 0 then  -- Left shift
            temp := input_vec(len-1-abs_shift downto 0) & (abs_shift-1 downto 0 => '0');
        else   -- Right shift
            temp := (abs_shift-1 downto 0 => '0') & input_vec(len-1 downto abs_shift);
        end if;
        
        return temp;
    end function;

    -- Helper function for ALU operations
    function alu_operation(
        op: std_logic_vector(2 downto 0);
        a, b: std_logic_vector(7 downto 0)
    ) return std_logic_vector is
    begin
        case op is
            when "000" => return a or b;         -- OR
            when "001" => return a nand b;        -- NAND
            when "010" => return a nor b;         -- NOR
            when "011" => return a and b;         -- AND
            when "100" => return std_logic_vector(unsigned(a) + unsigned(b));  -- ADD
            when "101" => return std_logic_vector(unsigned(a) - unsigned(b));  -- SUB
            when "110" => return a xor b;         -- XOR
            when "111" =>                        -- Barrel shift
                return expected_shift(a, to_integer(signed(b(3 downto 0))));
            when others => return "00000000";
        end case;
    end function;
        
    -- Helper function for condition checks
    function check_condition(
        cond: std_logic_vector(2 downto 0);
        op: signed(7 downto 0)
    ) return std_logic is
    begin
        case cond is
            when "000" => return '0';
            when "001" => 
                if op = 0 then return '1'; else return '0'; end if;
            when "010" => 
                if op < 0 then return '1'; else return '0'; end if;
            when "011" => 
                if op <= 0 then return '1'; else return '0'; end if;
            when "100" => return '1';
            when "101" => 
                if op /= 0 then return '1'; else return '0'; end if;
            when "110" => 
                if op >= 0 then return '1'; else return '0'; end if;
            when "111" => 
                if op > 0 then return '1'; else return '0'; end if;
            when others => return '0';
        end case;
    end function;
begin

    -- Instantiate DUT
    DUT: entity work.execute(rtl)
    port map (
        instruction_type => instruction_type,
        alu_op => alu_op,
        jump_condition => jump_condition,
        dst_reg_i => dst_reg_i,
        alu_operand_a => alu_operand_a,
        source_register => source_register,
        immediate_value => immediate_value,
        dst_reg_o => dst_reg_o,
        result_register => result_register,
        condition_result => condition_result
    );
    
    -- Test process
    test_proc: process
        variable l : line;
        variable seed1, seed2 : positive := 1;
        variable rand : real;
        variable rand_int : integer;
        variable expected_result : std_logic_vector(7 downto 0);
        variable expected_condition : std_logic;
        variable errors : integer := 0;

        type t_alu_op_counter is array (0 to 7) of integer;
        variable alu_op_count : t_alu_op_counter := (others => 0);
        type t_instr_counter is array (0 to 3) of integer;
        variable instr_count : t_instr_counter := (others => 0);
        
        -- Check result and report error
        procedure check(
            actual : std_logic_vector(7 downto 0);
            expected : std_logic_vector(7 downto 0);
            msg : string) is
        begin
            if instruction_type = "01" then
                if actual /= expected then
                    report "ERROR: " & msg & 
                           " ALU Opcode: " & to_string(alu_op) &
                           " R1: " & to_string(alu_operand_a) &
                           " R2: " & to_string(source_register) &
                            " Actual: " & to_string(actual) & 
                           " Expected: " & to_string(expected);
                end if;
            else
                if actual /= expected then
                    report "ERROR: " & msg & 
                            " Actual: " & to_string(actual) & 
                           " Expected: " & to_string(expected);
                end if;
            end if;
            if actual /= expected then
                errors := errors + 1;
            end if;
        end procedure;
        
        procedure check(
            actual : std_logic;
            expected : std_logic;
            msg : string) is
        begin
            if actual /= expected then
                report "ERROR: " & msg & 
                      " Actual: " & to_string(actual) & 
                      " Expected: " & to_string(expected);
                errors := errors + 1;
            end if;
        end procedure;
        
    begin
        -- Reset
        instruction_type <= "00";
        alu_op <= "000";
        jump_condition <= "000";
        dst_reg_i <= "000";
        alu_operand_a <= x"00";
        source_register <= x"00";
        immediate_value <= "000000";
        wait for CLK_PERIOD;
        
        -- Title
        report "---- Starting Manual Tests ----" severity note;
        
        ------------------------------------
        -- Test Load Immediate (Type 00) --
        ------------------------------------
        instruction_type <= "00";
        immediate_value <= "101010";
        wait for CLK_PERIOD;
        check(result_register, "00" & "101010", "Load Immediate");
        
        ------------------------------------
        -- Test ALU Operations (Type 01) --
        ------------------------------------
        instruction_type <= "01";
        alu_operand_a <= x"0F";  -- 00001111
        source_register <= x"F0"; -- 11110000
        
        -- OR (000)
        alu_op <= "000";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "OR operation");
        
        -- NAND (001)
        alu_op <= "001";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "NAND operation");
        
        -- NOR (010)
        alu_op <= "010";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "NOR operation");
        
        -- AND (011)
        alu_op <= "011";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "AND operation");
        
        -- ADD (100)
        alu_op <= "100";
        alu_operand_a <= x"0F";
        source_register <= x"01";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "ADD operation");
        
        -- SUB (101)
        alu_op <= "101";
        alu_operand_a <= x"10";
        source_register <= x"01";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "SUB operation");
        
        -- XOR (110)
        alu_op <= "110";
        alu_operand_a <= x"AA";
        source_register <= x"55";
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "XOR operation");
        
        -- Barrel Shift (111) - Left
        alu_op <= "111";
        alu_operand_a <= x"01";   -- 00000001
        source_register <= x"02"; -- Shift left by 2
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "Barrel Shift Left");
        
        -- Barrel Shift (111) - Right
        alu_op <= "111";
        alu_operand_a <= x"04";   -- 00000100
        source_register <= x"FE"; -- -2 (right shift by 2)
        wait for CLK_PERIOD;
        expected_result := alu_operation(alu_op, alu_operand_a, source_register);
        check(result_register, expected_result, "Barrel Shift Right");
        
        ------------------------------------
        -- Test Copy (Type 10) --
        ------------------------------------
        instruction_type <= "10";
        source_register <= x"AA";
        wait for CLK_PERIOD;
        check(result_register, x"AA", "Copy operation");
        
        ------------------------------------
        -- Test Conditions (Type 11) --
        ------------------------------------
        instruction_type <= "11";
        source_register <= x"00";  -- Zero
        
        jump_condition <= "000";  -- Never
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Never (0)");
        
        jump_condition <= "001";  -- Zero
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Zero (0)");
        
        jump_condition <= "100";  -- Always
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Always (0)");
        
        jump_condition <= "101";  -- Not zero
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Not Zero (0)");
        
        -- Test with negative value
        source_register <= x"FF";  -- -1 (signed)
        jump_condition <= "010";  -- Less than zero
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Negative");
        
        jump_condition <= "111";  -- Greater than zero
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Negative (GT)");
        
        -- Test with positive value
        source_register <= x"01";  -- +1
        jump_condition <= "110";  -- Greater or equal
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Positive (GE)");
        
        jump_condition <= "011";  -- Less or equal
        wait for CLK_PERIOD;
        expected_condition := check_condition(jump_condition, signed(source_register));
        check(condition_result, expected_condition, "Condition Positive (LE)");
        
        -- Report manual test results
        report "--- Manual Tests Complete ---" severity note;
        
        -- Skip random tests if manual tests failed
        if errors /= 0 then
            report "Skipping random tests due to manual test failures (" &
                integer'image(errors) & " errors)." severity warning;
            wait;
        end if;
        
        report "---- Starting Random Tests (" & integer'image(RANDOM_TESTS) & ") ----" severity note;
        
        --------------------------------
        -- Random Tests --
        --------------------------------
        for i in 1 to RANDOM_TESTS loop
            -- Generate random inputs
            uniform(seed1, seed2, rand);
            instruction_type <= std_logic_vector(to_unsigned(integer(floor(rand * 4.0)), 2));
            
            uniform(seed1, seed2, rand);
            alu_op <= std_logic_vector(to_unsigned(integer(floor(rand * 8.0)), 3));
            
            uniform(seed1, seed2, rand);
            jump_condition <= std_logic_vector(to_unsigned(integer(floor(rand * 8.0)), 3));
            
            uniform(seed1, seed2, rand);
            dst_reg_i <= std_logic_vector(to_unsigned(integer(floor(rand * 8.0)), 3));
            
            uniform(seed1, seed2, rand);
            alu_operand_a <= std_logic_vector(to_unsigned(integer(floor(rand * 256.0)), 8));
            
            uniform(seed1, seed2, rand);
            source_register <= std_logic_vector(to_unsigned(integer(floor(rand * 256.0)), 8));
            
            uniform(seed1, seed2, rand);
            immediate_value <= std_logic_vector(to_unsigned(integer(floor(rand * 64.0)), 6));
            
            wait for CLK_PERIOD;
            
            -- Check results
            case instruction_type is
                when "00" =>  -- Load Immediate
                    check(result_register, "00" & immediate_value, "Random Load Immediate");
                    instr_count(0) := instr_count(0) + 1;
                    
                when "01" =>  -- ALU/Compute
                    expected_result := alu_operation(alu_op, alu_operand_a, source_register);
                    check(result_register, expected_result, "Random ALU/Compute");
                    instr_count(1) := instr_count(1) + 1;
                    
                when "10" =>  -- Copy
                    check(result_register, source_register, "Random Copy");
                    instr_count(2) := instr_count(2) + 1;
                    
                when "11" =>  -- Jump/Branch
                    expected_condition := check_condition(jump_condition, signed(source_register));
                    check(condition_result, expected_condition, "Random Condition");
                    instr_count(3) := instr_count(3) + 1;
                    
                when others =>
                    null;
            end case;

            -- Count the instruction type and alu operation type,
            -- so we can report them later and ensure all types were tested
            -- good enough
            instr_count(to_integer(unsigned(instruction_type))) := instr_count(to_integer(unsigned(instruction_type))) + 1;
            if instruction_type = "01" then
                alu_op_count(to_integer(unsigned(alu_op))) := alu_op_count(to_integer(unsigned(alu_op))) + 1;
            end if;
        end loop;
        
        -- Final report
        if errors = 0 then
            report "All random tests passed successfully!" severity note;
        else
            report "Random tests completed with " & integer'image(errors) & " errors." severity warning;
        end if;

        -- Report instruction and ALU operation counts
        report "Instruction Type Counters: 01 (Load Immediate): " & integer'image(instr_count(0)) &
               ", 02 (ALU Operation): " & integer'image(instr_count(1)) &
               ", 03 (Copy Register): " & integer'image(instr_count(2)) &
               ", 04 (Jump / Branch): " & integer'image(instr_count(3)) severity note;
        
        report "ALU Operation Counts: 0 (OR): " & integer'image(alu_op_count(0)) &
               ", 1 (NAND): " & integer'image(alu_op_count(1)) &
               ", 2 (NOR): " & integer'image(alu_op_count(2)) &
               ", 3 (AND): " & integer'image(alu_op_count(3)) &
               ", 4 (ADD): " & integer'image(alu_op_count(4)) &
               ", 5 (SUB): " & integer'image(alu_op_count(5)) &
               ", 6 (XOR): " & integer'image(alu_op_count(6)) &
               ", 7 (Barrel Shift): " & integer'image(alu_op_count(7)) severity note;

        -- Finish simulation
        report "---- Testbench Complete ----" severity note;

        wait;
    end process;
end architecture;