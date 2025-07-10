

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soc_io is
	port (
		--! Clock input, synchronous with the system clock
		clk				: in std_logic;
		--! Reset input, active high
		reset			: in std_logic;
		
		--! Joystick down input, active high
		joystick_down	: in std_logic;
		--! Joystick right input, active high
		joystick_right	: in std_logic;
		--! Joystick up input, active high
		joystick_up		: in std_logic;
		--! Joystick left input, active high
		joystick_left			: in std_logic;
		--! Joystick center input, active high
		joystick_center			: in std_logic;

		--! UART receive input
		uart_rx					: in std_logic;

		--! UART transmit output
		uart_tx					: out std_logic;

		--! Parallel LEDs output, active-high
		leds					: out std_logic_vector(4 downto 0);

		--! Digital, serial RGB LED output
		rgbled_ser				: out std_logic;

		--! Address for I/O operations, 8 bits wide
		io_address				: in std_logic_vector(7 downto 0);
		--! Data to be written to I/O, 8 bits wide
		io_data_write			: in std_logic_vector(7 downto 0);
		--! Data read from I/O, 8 bits wide
		io_data_read			: out std_logic_vector(7 downto 0);
		--! Write enable signal for I/O operations
		io_data_write_enable : in std_logic
	);
end entity soc_io;

architecture rtl of soc_io is

	signal io_RAM_address       : std_logic_vector(3 downto 0);
	signal io_RAM_write_enable  : std_logic;
	signal io_RAM_data_to_RAM   : std_logic_vector(7 downto 0);
	signal io_RAM_data_from_RAM : std_logic_vector(7 downto 0);

begin

	--! 16 bytes of RAM for the Overture CPU, accessible via the I/O interface
	OVERTURE_RAM : entity work.ram(rtl)
		generic map (
			RAM_SIZE => 16
		)
		port map (
			clk_i			=> clk,
			reset_i			=> reset,
			address_i		=> io_RAM_address,
			write_enable_i	=> io_RAM_write_enable,
			data_in_i		=> io_RAM_data_to_RAM,
			data_out_o		=> io_RAM_data_from_RAM
	);

end architecture;