-- Dependency: src/overture/condition.vhdl
-- TEROSHDL Documentation:
--! @title Condition Check Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 07.07.2025
--! @brief Testbench for the condition check unit
--!
--! This testbench verifies the functionality of the condition check unit.
--! It tests both the `rtl` and `turing_complete` architectures.
--! The testbench includes hand-coded test vectors and a number of random tests.
--! 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_condition is
end entity tb_condition;

architecture behavior of tb_condition is

    --! Test record and array type
    type test_record is record
        op      : std_logic_vector(2 downto 0);
        operand : signed(7 downto 0);
        expected: std_logic;
    end record;
    
    type test_vector_array is array (natural range <>) of test_record;
    
    --! Number of random tests per condition
    constant N_AMOUNT_TESTS : natural := 1000; 

    --! Hand-coded test vectors
    constant test_vectors : test_vector_array := (
        -- op = "000" (never branch)
        ("000", to_signed(0, 8),    '0'),
        ("000", to_signed(1, 8),    '0'),
        ("000", to_signed(-1, 8),   '0'),
        ("000", to_signed(127, 8),  '0'),
        ("000", to_signed(-128, 8), '0'),
        ("000", to_signed(42, 8),   '0'),
        ("000", to_signed(-42, 8),  '0'),

        -- op = "001" (zero)
        ("001", to_signed(0, 8),    '1'),
        ("001", to_signed(1, 8),    '0'),
        ("001", to_signed(-1, 8),   '0'),
        ("001", to_signed(127, 8),  '0'),
        ("001", to_signed(-128, 8), '0'),
        ("001", to_signed(42, 8),   '0'),
        ("001", to_signed(-42, 8),  '0'),

        -- op = "010" (less than zero)
        ("010", to_signed(0, 8),    '0'),
        ("010", to_signed(1, 8),    '0'),
        ("010", to_signed(-1, 8),   '1'), -- -1
        ("010", to_signed(127, 8),  '0'),
        ("010", to_signed(-128, 8), '1'), -- -128
        ("010", to_signed(42, 8),   '0'),
        ("010", to_signed(-42, 8),  '1'), -- -42

        -- op = "011" (less or equal zero)
        ("011", to_signed(0, 8),    '1'),
        ("011", to_signed(1, 8),    '0'),
        ("011", to_signed(-1, 8),   '1'),
        ("011", to_signed(127, 8),  '0'),
        ("011", to_signed(-128, 8), '1'),
        ("011", to_signed(42, 8),   '0'),
        ("011", to_signed(-42, 8),  '1'),

        -- op = "100" (always branch)
        ("100", to_signed(0, 8),    '1'),
        ("100", to_signed(1, 8),    '1'),
        ("100", to_signed(-1, 8),   '1'),
        ("100", to_signed(127, 8),  '1'),
        ("100", to_signed(-128, 8), '1'),
        ("100", to_signed(42, 8),   '1'),
        ("100", to_signed(-42, 8),  '1'),

        -- op = "101" (not zero)
        ("101", to_signed(0, 8),    '0'),
        ("101", to_signed(1, 8),    '1'),
        ("101", to_signed(-1, 8),   '1'),
        ("101", to_signed(127, 8),  '1'),
        ("101", to_signed(-128, 8), '1'),
        ("101", to_signed(42, 8),   '1'),
        ("101", to_signed(-42, 8),  '1'),

        -- op = "110" (greater or equal zero)
        ("110", to_signed(0, 8),    '1'),
        ("110", to_signed(1, 8),    '1'),
        ("110", to_signed(-1, 8),   '0'),
        ("110", to_signed(127, 8),  '1'),
        ("110", to_signed(-128, 8), '0'),
        ("110", to_signed(42, 8),   '1'),
        ("110", to_signed(-42, 8),  '0'),

        -- op = "111" (greater than zero)
        ("111", to_signed(0, 8),    '0'),
        ("111", to_signed(1, 8),    '1'),
        ("111", to_signed(-1, 8),   '0'),
        ("111", to_signed(127, 8),  '1'),
        ("111", to_signed(-128, 8), '0'),
        ("111", to_signed(42, 8),   '1'),
        ("111", to_signed(-42, 8),  '0')
    );
    
    -- Function to compute expected result
    function expected_condition(
        condition_op : std_logic_vector(2 downto 0);
        operand      : signed(7 downto 0)
    ) return std_logic is
    begin
        case condition_op is
            when "000" => return '0';
            when "001" => 
                if operand = 0 then return '1'; else return '0'; end if;
            when "010" => 
                if operand < 0 then return '1'; else return '0'; end if;
            when "011" => 
                if operand <= 0 then return '1'; else return '0'; end if;
            when "100" => return '1';
            when "101" => 
                if operand /= 0 then return '1'; else return '0'; end if;
            when "110" => 
                if operand >= 0 then return '1'; else return '0'; end if;
            when "111" => 
                if operand > 0 then return '1'; else return '0'; end if;
            when others => return '0';
        end case;
    end function;
    
    -- Signals for UUT connections
    signal op           : std_logic_vector(2 downto 0);
    signal operand      : signed(7 downto 0);
    signal result_rtl   : std_logic;
    signal result_tc    : std_logic;

begin

    -- Unit Under Test (rtl architecture)
    DUT_RTL: entity work.condition(rtl)
        port map (
            condition_op_i => op,
            operand_i => operand,
            result_o => result_rtl
        );
    -- Unit Under Test (turing_complete architecture)
    DUT_TC: entity work.condition(turing_complete)
        port map (
            condition_op_i => op,
            operand_i => operand,
            result_o => result_tc
        );
    
    -- Test process
    process
        variable errors : natural := 0;
        variable expected : std_logic;
        variable seed1, seed2 : positive := 1;
        variable rand : real;
        variable int_rand : integer;
        variable total_errors : natural := 0;
    begin
        report "Starting test for RTL architecture...";
        
        -- Hand-coded tests
        for i in test_vectors'range loop
            op <= test_vectors(i).op;
            operand <= test_vectors(i).operand;
            wait for 10 ns;
            
            expected := expected_condition(op, operand);
            if result_rtl /= expected then
                report "Error (Hand-coded): op=" & to_string(op) & 
                       ", operand=" & to_string(operand) & 
                       ", expected=" & to_string(expected) & 
                       ", got=" & to_string(result_rtl)
                severity error;
                errors := errors + 1;
            end if;
        end loop;
        
        -- If the hand-coded tests already fail, abort simulation
        if errors > 0 then
            report "RTL: " & integer'image(errors) & " errors found!" severity failure;
            wait;  -- Stop simulation on failure
        end if;

        -- Random tests
        for op_val in 0 to 7 loop
            for i in 1 to N_AMOUNT_TESTS loop
                uniform(seed1, seed2, rand);
                int_rand := integer(trunc(rand * 256.0));
                operand <= signed(std_logic_vector(to_unsigned(int_rand, 8)));
                op <= std_logic_vector(to_unsigned(op_val, 3));
                wait for 10 ns;
                
                expected := expected_condition(op, operand);
                if result_rtl /= expected then
                    report "Error (Random): op=" & to_string(op) & 
                           ", operand=" & to_string(operand) & 
                           ", expected=" & to_string(expected) & 
                           ", got=" & to_string(result_rtl)
                    severity error;
                    errors := errors + 1;
                end if;
            end loop;
        end loop;
        
        -- Report results for RTL
        if errors = 0 then
            report "RTL: All tests passed!";
        else
            report "RTL: " & integer'image(errors) & " errors found!" severity error;
        end if;
        total_errors := total_errors + errors;
        errors := 0;
        
        wait for 20 ns;  -- Ensure no pending events        
        report "Starting test for turing_complete architecture...";
        
        -- Hand-coded tests
        for i in test_vectors'range loop
            op <= test_vectors(i).op;
            operand <= test_vectors(i).operand;
            wait for 10 ns;
            
            expected := expected_condition(op, operand);
            if result_tc /= expected then
                report "Error (Hand-coded): op=" & to_string(op) & 
                       ", operand=" & to_string(operand) & 
                       ", expected=" & to_string(expected) & 
                       ", got=" & to_string(result_tc)
                severity error;
                errors := errors + 1;
            end if;
        end loop;

        -- If the hand-coded tests already fail, abort simulation
		if errors > 0 then
			report "turing_complete: " & integer'image(errors) & " errors found!" severity failure;
			wait;  -- Stop simulation on failure
		end if;
        
        -- Random tests
        for op_val in 0 to 7 loop
            for i in 1 to N_AMOUNT_TESTS loop
                uniform(seed1, seed2, rand);
                int_rand := integer(trunc(rand * 256.0));
                operand <= signed(std_logic_vector(to_unsigned(int_rand, 8)));
                op <= std_logic_vector(to_unsigned(op_val, 3));
                wait for 10 ns;
                
                expected := expected_condition(op, operand);
                if result_tc /= expected then
                    report "Error (Random): op=" & to_string(op) & 
                           ", operand=" & to_string(operand) & 
                           ", expected=" & to_string(expected) & 
                           ", got=" & to_string(result_tc)
                    severity error;
                    errors := errors + 1;
                end if;
            end loop;
        end loop;
        
        -- Report results for turing_complete
        if errors = 0 then
            report "turing_complete: All tests passed!";
        else
            report "turing_complete: " & integer'image(errors) & " errors found!" severity error;
        end if;
        total_errors := total_errors + errors;
        
        -- Final report
        if total_errors = 0 then
            report "ALL TESTS PASSED!";
        else
            report integer'image(total_errors) & " TOTAL ERRORS FOUND!" severity error;
        end if;

        -- Stop the simulation
        wait;
    end process;
	
end architecture behavior;