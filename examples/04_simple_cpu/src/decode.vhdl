-- TEROSHDL Documentation:
--! @title Decode Unit
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Decode Unit for a simple CPU
--!
--! This VHDL code implements a simple decode unit for a CPU.
--! It decodes the fetched instruction into control signals for the ALU and register addresses.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
	port (
		--! Fetched instruction input to decode into control signals
		fetched_instruction : in std_logic_vector(7 downto 0);

		--! Instruction type
		instruction_type : out std_logic_vector(1 downto 0);
		--! Decoded ALU operation
		alu_op : out std_logic_vector(2 downto 0);
		--! Source register address
		src_reg : out std_logic_vector(2 downto 0);
		--! Destination register address
		dst_reg : out std_logic_vector(2 downto 0)
	);
end entity decode;

architecture rtl of decode is

begin

	-- Decode the respective fields from the fetched instruction
	instruction_type	<= fetched_instruction(7 downto 6); -- Instruction type bits
	alu_op				<= fetched_instruction(2 downto 0); -- ALU operation bits
	src_reg				<= fetched_instruction(5 downto 3); -- Source register bits
	dst_reg				<= fetched_instruction(2 downto 0); -- Destination register bits

end architecture;