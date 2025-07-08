-- TEROSHDL Documentation:
--! @title Simple ALU
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief ALU for a simple CPU
--!
--! This VHDL code implements a simple ALU for a CPU.
--! It supports seven basic arithmetic and logical operations. The following operations are supported:
--! 0. OR: R3 = R1 | R2
--! 1. NAND: R3 = ~(R1 & R2)
--! 2. NOR: R3 = ~(R1 | R2)
--! 3. AND: R3 = R1 & R2
--! 4. ADD: R3 = R1 + R2
--! 5. SUB: R3 = R1 - R2
--! 6. XOR: R3 = R1 ^ R2
--!
--! Two architectures are provided:
--! - `rtl` (default): Uses a process with a case statement to perform the ALU operations.
--! - `with_select`: Uses a with-select statement to perform the ALU operations.
--!
--! The `with_select` architecture is less readable and maintainable compared to 
--! the `rtl` architecture, but it demonstrates the use of a with-select statement.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        --! ALU operation control signal
        alu_op_i    : in std_logic_vector(2 downto 0);

        --! Operand A to perform the ALU operation on
        operand_a_i : in std_logic_vector(7 downto 0);
        --! Operand B to perform the ALU operation on
        operand_b_i : in std_logic_vector(7 downto 0);

        --! Result of the ALU operation
        result_o    : out std_logic_vector(7 downto 0)
    );
end entity alu;

architecture rtl of alu is
begin

    --! Perform the ALU operation based on the alu_op control signal.
    ALU_OPERATION : process (alu_op_i, operand_a_i, operand_b_i)
    begin

        case alu_op_i is
            when "000" =>  -- OR operation: R3 = R1 | R2
                result_o <= operand_a_i or operand_b_i;
            when "001" =>  -- NAND operation: R3 = ~(R1 & R2)
                result_o <= operand_a_i nand operand_b_i;
            when "010" =>  -- NOR operation: R3 = ~(R1 | R2)
                result_o <= operand_a_i nor operand_b_i;
            when "011" =>  -- AND operation: R3 = R1 & R2
                result_o <= operand_a_i and operand_b_i;
            when "100" =>  -- ADD operation: R3 = R1 + R2
                result_o <= std_logic_vector(unsigned(operand_a_i) + unsigned(operand_b_i));
            when "101" =>  -- SUB operation: R3 = R1 - R2
                result_o <= std_logic_vector(unsigned(operand_a_i) - unsigned(operand_b_i));
            when "110" =>  -- XOR operation: R3 = R1 ^ R2
                result_o <= operand_a_i xor operand_b_i;
            when others =>  -- Default case: R3 = 0
                result_o <= (others => '0');
        end case;

    end process ALU_OPERATION;

end architecture;

architecture with_select of alu is
begin

    -- While you could use a with-select statement here, a proper case statement
    -- in a process body is more readable and maintainable. Still, the example
    -- below lets you see how to use a with-select statement.

    with alu_op_i select 
        result_o <= operand_a_i or operand_b_i                                      when "000",  -- OR operation: R3 = R1 | R2
                    operand_a_i nand operand_b_i                                    when "001",  -- NAND operation: R3 = ~(R1 & R2)
                    operand_a_i nor operand_b_i                                     when "010",  -- NOR operation: R3 = ~(R1 | R2)
                    operand_a_i and operand_b_i                                     when "011",  -- AND operation: R3 = R1 & R2
                    std_logic_vector(unsigned(operand_a_i) + unsigned(operand_b_i)) when "100",  -- ADD operation: R3 = R1 + R2
                    std_logic_vector(unsigned(operand_a_i) - unsigned(operand_b_i)) when "101",  -- SUB operation: R3 = R1 - R2
                    operand_a_i xor operand_b_i                                     when "110",  -- XOR operation: R3 = R1 ^ R2
                    "00000000" when others;                                                      -- Default case: R3 = 0

end architecture;