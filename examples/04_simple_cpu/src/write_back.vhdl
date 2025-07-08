-- TEROSHDL Documentation
--! @title Write Back Unit
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Write Back Unit for a simple CPU
--!
--! This Write Back Unit in VHDL implements the final stage of a simple CPU's instruction execution cycle.
--! It handles the writing of results back to either the register file or I/O devices based on the instruction type.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
	port (
		--! Instruction type, used to determine the write-back operation
		instruction_type_i : in std_logic_vector(1 downto 0);
		--! Destination register address, used to determine where to write the result
		dst_reg_i : in std_logic_vector(2 downto 0);
		--! Result data to be written back, either from ALU or immediate value
		result_data_i : in std_logic_vector(7 downto 0);

		--! Outputs for writing back to registers or I/O
		register_data_o : out std_logic_vector(7 downto 0);
		--! Control signals for writing back to registers and I/O
		registers_write_enable_o : out std_logic;
		--! Address of the register to write back to, or I/O address
		registers_write_address_o : out std_logic_vector(2 downto 0);

		--! Data to be written to I/O, if applicable
		io_data_o : out std_logic_vector(7 downto 0);
		--! Control signal to enable writing to I/O
		io_data_write_enable_o : out std_logic
		
	);
end entity write_back;

architecture rtl of write_back is
begin

	--! Write Back process that handles the final stage of instruction execution
	--! It determines whether to write back to registers or I/O based on the instruction type
	WB : process (instruction_type_i, dst_reg_i, result_data_i)
	begin
		
		register_data_o <= result_data_i; -- Default output for register data
		registers_write_address_o <= dst_reg_i;
		io_data_o <= result_data_i;
		registers_write_enable_o <= '0';
		io_data_write_enable_o <= '0';

		case instruction_type_i is
			when "00" | "01" => -- Load immediate or ALU operation
				registers_write_enable_o <= '1'; -- Enable register write
			when "10" => -- I/O operation
				if dst_reg_i = "111" then -- Write to io
					io_data_o <= result_data_i; -- Write data to I/O
					io_data_write_enable_o <= '1'; -- Enable I/O write
				else
					registers_write_address_o <= dst_reg_i; -- Write to register
					registers_write_enable_o <= '1';
				end if;
			when others =>
				-- No write-back for other instruction types
				null;
		end case;

	end process WB;

end architecture;