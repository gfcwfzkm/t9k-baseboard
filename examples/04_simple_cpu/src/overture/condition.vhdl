-- TEROSHDL Documentation:
--! @title Condition Check
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Checks certain conditions and outputs a result signal
--!
--! This VHDL code implements a condition check unit for a CPU.
--! It checks 8 different conditions based on the input signals and outputs a result signal if the selected condition is met.
--! The operand is an 8-bit signed value.
--!
--! The following conditions are implemented and `result` is set to '1' if the condition is met:
--! - `000`: Never branch (result is always '0')
--! - `001`: Operand is zero
--! - `010`: Operand is less than zero
--! - `011`: Operand is less than or equal to zero
--! - `100`: Always branch (result is always '1')
--! - `101`: Operand is not zero
--! - `110`: Operand is greater than or equal to zero
--! - `111`: Operand is greater than zero
--!
--! Two architectures are provided:
--! - `rtl`: A readable implementation that checks conditions based on the input signals.
--! - `turing_complete`: A less readable implementation that demonstrates a solution from the game Turing Complete.
--!   - ![Turing Complete - Condition Level](https://raw.githubusercontent.com/gfcwfzkm/t9k-baseboard/refs/heads/simple-cpu/examples/04_simple_cpu/images/turing_complete_conditions.png)
--!
--! The `rtl` architecture is designed to be easy to understand and maintain, 
--! while the `turing_complete` architecture serves as an example of how to implement
--! solutions from the game Turing Complete in VHDL.
--! 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity condition is
    port (
        --! Condition operation code to select the condition to check
        condition_op_i  : in std_logic_vector(2 downto 0);
        --! Operand (signed, two's complement) to check the condition against
        operand_i       : in signed(7 downto 0);
        --! Result signal that is set to '1' if the condition is met, otherwise '0'
        result_o        : out std_logic
    );
end entity;

architecture rtl of condition is
begin

    --! Process to check the condition based on the condition_op and operand
    CONDITION_CHECK : process (condition_op_i, operand_i) begin
        case condition_op_i is
            when "000" =>
                -- Never branch
                result_o <= '0';
            when "001" =>
                -- Operand is zero
                if operand_i = 0 then
                    result_o <= '1';
                else
                    result_o <= '0';
                end if;
            when "010" =>
                -- Operand is less than zero
                if operand_i < 0 then
                    result_o <= '1';
                else
                    result_o <= '0';
                end if;
            when "011" =>
                -- Operand is less than or equal to zero
                if operand_i <= 0 then
                    result_o <= '1';
                else
                    result_o <= '0';
                end if;
            when "100" =>
                -- Always branch
                result_o <= '1';
            when "101" =>
                -- Operand is not zero
                if operand_i /= 0 then
                    result_o <= '1';
                else
                    result_o <= '0';
                end if;
            when "110" =>
                -- Operand is greater than or equal to zero
                if operand_i >= 0 then
                    result_o <= '1';
                else
                    result_o <= '0';
                end if;
            when "111" =>
                -- Operand is greater than zero
                if operand_i > 0 then
                    result_o <= '1';
                else
                    result_o <= '0';
                end if;
            when others =>
                result_o <= '0';
        end case;
    end process CONDITION_CHECK;

end architecture;

architecture turing_complete of condition is
    --! This architecture is a placeholder to demonstrate the solution from the game Turing Complete.
    --! It does not implement any other specific functionality and is less readable than the `rtl` architecture.
    --! Still, it serves as an example how you can implement your game solutions in VHDL, if you want to.

    -- Intermediate signals for condition checks
    --! Wired to the most-significant bit of the operand to check if the result is negative
    signal is_result_negative       : std_logic;
    --! ORed result of the operand, except of the most-significant bit.
    signal is_result_non_zero       : std_logic;

    -- Result signals for each condition
    signal cond_never_branch        : std_logic;
    signal cond_equal_zero          : std_logic;
    signal cond_less_than_zero      : std_logic;
    signal cond_less_equal_zero     : std_logic;
    signal cond_always_branch       : std_logic;
    signal cond_not_equal_zero      : std_logic;
    signal cond_greater_equal_zero  : std_logic;
    signal cond_greater_than_zero   : std_logic;
begin

    -- First get the intermediate signals
    is_result_negative <= operand_i(7);
    is_result_non_zero <= or operand_i(6 downto 0);	-- VHDL-2008 feature!
    -- If the above does not work, then you're probably on VHDL-1993 (poor Intel Quartus users),
    -- comment out the problematic line and uncomment the one below:
    -- is_result_non_zero <= '0' when unsigned(operand(6 downto 0)) = 0 else '1';

    -- Now check the conditions
    cond_never_branch       <= '0';
    cond_equal_zero         <= is_result_non_zero nor is_result_negative;
    cond_less_than_zero     <= is_result_negative;
    cond_less_equal_zero    <= is_result_negative or cond_equal_zero;
    cond_always_branch      <= '1';
    cond_not_equal_zero     <= is_result_negative or is_result_non_zero;
    cond_greater_equal_zero <= cond_equal_zero or cond_greater_than_zero;
    cond_greater_than_zero  <= (not is_result_negative) and is_result_non_zero;

    -- Finally, assign the result based on the condition_op
    -- Basically one big multiplexer to select the result based on the condition_op
    with condition_op_i select
        result_o  <= 	cond_never_branch       when "000",
                    cond_equal_zero         when "001",
                    cond_less_than_zero     when "010",
                    cond_less_equal_zero    when "011",
                    cond_always_branch      when "100",
                    cond_not_equal_zero     when "101",
                    cond_greater_equal_zero when "110",
                    cond_greater_than_zero  when "111",
                    '0' when others;
    -- With verbose signal names and otherwise no long operations, this is
    -- the only case I personally would use a with-select statement to "type less".

end architecture;