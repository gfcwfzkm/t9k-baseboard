-- TEROSHDL Documentation:
--! @title ALU
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief ALU for a simple CPU
--!
--! This VHDL code implements a simple ALU for a CPU.
--! It supports basic arithmetic and logical operations, including addition, subtraction, AND, OR, XOR, NAND and NOR.
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
		alu_op		: in std_logic_vector(2 downto 0);

		--! Operand A to perform the ALU operation on
		operand_a	: in std_logic_vector(7 downto 0);
		--! Operand B to perform the ALU operation on
		operand_b	: in std_logic_vector(7 downto 0);

		--! Result of the ALU operation
		result		: out std_logic_vector(7 downto 0)
	);
end entity alu;

architecture rtl of alu is
begin

	--! Perform the ALU operation based on the alu_op control signal.
	ALU_OPERATION : process (alu_op, operand_a, operand_b)
	begin

		case alu_op is
			when "000" =>  -- OR operation: R3 = R1 | R2
				result <= operand_a or operand_b;
			when "001" =>  -- NAND operation: R3 = ~(R1 & R2)
				result <= operand_a nand operand_b;
			when "010" =>  -- NOR operation: R3 = ~(R1 | R2)
				result <= operand_a nor operand_b;
			when "011" =>  -- AND operation: R3 = R1 & R2
				result <= operand_a and operand_b;
			when "100" =>  -- ADD operation: R3 = R1 + R2
				result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));
			when "101" =>  -- SUB operation: R3 = R1 - R2
				result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));
			when "110" =>  -- XOR operation: R3 = R1 ^ R2
				result <= operand_a xor operand_b;
			when others =>  -- Default case: R3 = 0
				result <= (others => '0');
		end case;

	end process ALU_OPERATION;

end architecture;

architecture with_select of alu is
begin

	-- While you could use a with-select statement here, a proper case statement
	-- in a process body is more readable and maintainable. Still, the example
	-- below lets you see how to use a with-select statement.

	with alu_op select 
	result  <=	operand_a or operand_b 										when "000",  -- OR operation: R3 = R1 | R2
			 	operand_a nand operand_b									when "001",  -- NAND operation: R3 = ~(R1 & R2)
				operand_a nor operand_b										when "010",  -- NOR operation: R3 = ~(R1 | R2)
				operand_a and operand_b										when "011",  -- AND operation: R3 = R1 & R2
				std_logic_vector(unsigned(operand_a) + unsigned(operand_b)) when "100",  -- ADD operation: R3 = R1 + R2
				std_logic_vector(unsigned(operand_a) - unsigned(operand_b)) when "101",  -- SUB operation: R3 = R1 - R2
				operand_a xor operand_b										when "110",  -- XOR operation: R3 = R1 ^ R2
			  	"00000000" when others;	-- Default case: R3 = 0

end architecture;