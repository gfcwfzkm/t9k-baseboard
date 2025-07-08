
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
	port (
		instruction_type_i : in std_logic_vector(1 downto 0);

		dst_reg_i : in std_logic_vector(2 downto 0);

		result_data_i : in std_logic_vector(7 downto 0);

		register_data_o : out std_logic_vector(7 downto 0);
		registers_write_enable_o : out std_logic;
		registers_write_address_o : out std_logic_vector(2 downto 0);

		io_data_o : out std_logic_vector(7 downto 0);
		io_data_write_enable_o : out std_logic
		
	);
end entity write_back;

architecture rtl of write_back is
begin

	process (instruction_type_i, dst_reg_i, result_data_i)
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

	end process;

end architecture;