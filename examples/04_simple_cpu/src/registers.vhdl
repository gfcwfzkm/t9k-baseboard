-- TEROSHDL Documentation
--! @title Register File
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Register file for a simple CPU
--!
--! This VHDL code implements a register file for a simple CPU.
--! It contains 7 registers, each 8 bits wide. The register file supports reading and writing to registers.
--! The following operations are supported:
--! - Writing data to a register
--! - Reading data from a register
--! - Resetting all registers to 0
--!
--! The register file also provides direct outputs for the special registers for jump address, I/O address, and ALU operand A.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
	port (
		clk   : in std_logic;
		reset : in std_logic;
		
		write_address : in std_logic_vector(2 downto 0);
		write_data    : in std_logic_vector(7 downto 0);
		write_enable  : in std_logic;

		read_address  : in std_logic_vector(2 downto 0);
		read_data     : out std_logic_vector(7 downto 0);

		jump_address  : out std_logic_vector(7 downto 0);
		alu_operand_a : out std_logic_vector(7 downto 0);
		io_address    : out std_logic_vector(7 downto 0)
	);
end entity registers;

architecture rtl of registers is

	type t_registers is array (0 to 6) of std_logic_vector(7 downto 0);
	signal registers : t_registers;

begin

	-- Read data from the specified register
	read_data <= registers(to_integer(unsigned(read_address))) when unsigned(read_address) < registers'length else (others => '0');
	jump_address <= registers(0); -- Register 0 holds the jump address
	io_address <= registers(6); -- Register 6 holds the I/O address

	CLKREG : process (clk, reset)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				registers <= (others => (others => '0')); -- Reset all registers to 0
			else
				registers <= registers; -- Keep current state

				if write_enable = '1' and unsigned(write_address) < registers'length then
					-- Write data to the specified register
					registers(to_integer(unsigned(write_address))) <= write_data;
				end if;
			end if;
		end if;
	end process CLKREG;

end architecture;