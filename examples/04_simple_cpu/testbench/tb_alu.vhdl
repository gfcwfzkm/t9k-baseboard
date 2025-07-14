-- Dependency: src/overture/alu.vhdl
-- TEROSHDL Documentation:
--! @title ALU Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 07.07.2025
--! @brief Testbench for the ALU unit
--!
--! This testbench verifies the functionality of the ALU unit.
--! The testbench includes hand-coded test vectors and a number of random tests.
--! 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_alu is
end entity tb_alu;

architecture tb of tb_alu is

    --! Number of random tests per ALU operation
    constant NUM_RANDOM_TESTS : natural := 100;
    
    -- UUT signals
    signal alu_op    : std_logic_vector(2 downto 0);
    signal operand_a : std_logic_vector(7 downto 0);
    signal operand_b : std_logic_vector(7 downto 0);
    signal result    : std_logic_vector(7 downto 0);
    
    -- Test case record
    type test_case_t is record
        op      : std_logic_vector(2 downto 0);
        a       : std_logic_vector(7 downto 0);
        b       : std_logic_vector(7 downto 0);
        expected: std_logic_vector(7 downto 0);
    end record;
    
    type test_case_array_t is array (natural range <>) of test_case_t;
    
    -- Hand-written edge cases
    constant edge_cases : test_case_array_t := (
        -- OR operations
        (op => "000", a => "00000000", b => "00000000", expected => "00000000"),
        (op => "000", a => "11111111", b => "00000000", expected => "11111111"),
        (op => "000", a => "01010101", b => "10101010", expected => "11111111"),
        
        -- NAND operations
        (op => "001", a => "00000000", b => "00000000", expected => "11111111"),
        (op => "001", a => "11111111", b => "11111111", expected => "00000000"),
        (op => "001", a => "01010101", b => "10101010", expected => "11111111"),
        
        -- NOR operations
        (op => "010", a => "00000000", b => "00000000", expected => "11111111"),
        (op => "010", a => "11111111", b => "11111111", expected => "00000000"),
        (op => "010", a => "01010101", b => "10101010", expected => "00000000"),
        
        -- AND operations
        (op => "011", a => "00000000", b => "00000000", expected => "00000000"),
        (op => "011", a => "11111111", b => "11111111", expected => "11111111"),
        (op => "011", a => "01010101", b => "10101010", expected => "00000000"),
        
        -- ADD operations
        (op => "100", a => "00000000", b => "00000000", expected => "00000000"),
        (op => "100", a => "00000001", b => "00000001", expected => "00000010"),
        (op => "100", a => "11111111", b => "00000001", expected => "00000000"),
        (op => "100", a => "01111111", b => "00000001", expected => "10000000"),
        
        -- SUB operations
        (op => "101", a => "00000010", b => "00000001", expected => "00000001"),
        (op => "101", a => "00000000", b => "00000001", expected => "11111111"),
        (op => "101", a => "00000001", b => "00000010", expected => "11111111"),
        (op => "101", a => "10000000", b => "10000000", expected => "00000000"),
        
        -- XOR operations
        (op => "110", a => "00000000", b => "00000000", expected => "00000000"),
        (op => "110", a => "11111111", b => "11111111", expected => "00000000"),
        (op => "110", a => "01010101", b => "10101010", expected => "11111111"),
        
        -- Default case
        (op => "111", a => "01010101", b => "10101010", expected => "00000000")
    );
    
    --! ALU reference model
    function alu_ref(
        op : std_logic_vector(2 downto 0);
        a  : std_logic_vector(7 downto 0);
        b  : std_logic_vector(7 downto 0)
    ) return std_logic_vector is
    begin
        case op is
            when "000" => return a or b;
            when "001" => return a nand b;
            when "010" => return a nor b;
            when "011" => return a and b;
            when "100" => return std_logic_vector(unsigned(a) + unsigned(b));
            when "101" => return std_logic_vector(unsigned(a) - unsigned(b));
            when "110" => return a xor b;
            when others => return "00000000";
        end case;
    end function;

begin

    -- Unit Under Test
    DUT: entity work.alu(rtl)
        port map (
            alu_op_i    => alu_op,
            operand_a_i => operand_a,
            operand_b_i => operand_b,
            result_o    => result
        );
    
    -- Test process
    process
        variable seed1, seed2 : positive := 1;
        variable rand_real    : real;
        variable error_count  : natural := 0;
        variable rand_a       : std_logic_vector(7 downto 0);
        variable rand_b       : std_logic_vector(7 downto 0);
    begin
        -- 1. Test hand-written edge cases
        report "Testing edge cases...";
        for i in edge_cases'range loop
            alu_op    <= edge_cases(i).op;
            operand_a <= edge_cases(i).a;
            operand_b <= edge_cases(i).b;
            wait for 10 ns;
            
            if result /= edge_cases(i).expected then
                report "Edge case " & integer'image(i) & " failed!" & lf &
                       "OP: " & to_string(edge_cases(i).op) & 
                       " A: " & to_string(edge_cases(i).a) & 
                       " B: " & to_string(edge_cases(i).b) & lf &
                       "Got: " & to_string(result) & 
                       " Expected: " & to_string(edge_cases(i).expected)
                       severity error;
                error_count := error_count + 1;
            end if;
        end loop;
        
        -- Abort if edge cases failed
        if error_count > 0 then
            report "Edge cases failed! (" & integer'image(error_count) & " errors)";
            report "Skipping random tests due to edge case failures";
            wait;
        end if;
        
        -- 2. Operation-focused random tests
        report "Testing " & integer'image(NUM_RANDOM_TESTS) & 
               " random cases per ALU operation (" & 
               integer'image(NUM_RANDOM_TESTS * 7) & " total)...";
        
        -- Test each operation (excluding default case)
        for op_val in 0 to 6 loop
            alu_op <= std_logic_vector(to_unsigned(op_val, 3));
            
            for i in 1 to NUM_RANDOM_TESTS loop
                -- Generate random operands
                for j in 0 to 7 loop
                    uniform(seed1, seed2, rand_real);
                    rand_a(j) := '1' when rand_real > 0.5 else '0';
                    uniform(seed1, seed2, rand_real);
                    rand_b(j) := '1' when rand_real > 0.5 else '0';
                end loop;
                
                operand_a <= rand_a;
                operand_b <= rand_b;
                wait for 10 ns;
                
                -- Check against reference model
                if result /= alu_ref(alu_op, operand_a, operand_b) then
                    report "Operation " & to_string(alu_op) & " case " & 
                           integer'image(i) & " failed!" & lf &
                           "A: " & to_string(operand_a) & 
                           " B: " & to_string(operand_b) & lf &
                           "Got: " & to_string(result) & 
                           " Expected: " & to_string(alu_ref(alu_op, operand_a, operand_b))
                           severity error;
                    error_count := error_count + 1;
                end if;
            end loop;
        end loop;
        
        -- Final report
        if error_count = 0 then
            report "All tests passed!" severity note;
        else
            report "Test completed with " & integer'image(error_count) & " errors" severity note;
        end if;
        
        wait;
    end process;

end architecture tb;