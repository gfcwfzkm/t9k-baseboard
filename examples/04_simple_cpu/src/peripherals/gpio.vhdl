-- TEROSHDL Documentation:
--! @title GPIO Module
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 11.07.2025
--! @brief A simple GPIO module with debounced inputs and outputs.
--!
--! This module implements a simple GPIO interface with debounced inputs for joystick buttons
--! and outputs for LEDs. The debouncing is done using a debouncer component.
--! The GPIO operations are controlled by an address, write enable, and read enable signals.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio is
	generic (
		--! GPIO I/O Address
		PERIPHERAL_ADDRESS : std_logic_vector(7 downto 0)
	);
	port (
		--! Clock input, synchronous with the system clock
		clk				: in std_logic;
		--! Reset input, synchronous, active high
		reset			: in std_logic;
		
		-- GPIO Inputs and Outputs
		--! GPIO inputs, joystick buttons
		joystick		: in std_logic_vector(4 downto 0);
		--! GPIO outputs, parallel LEDs
		leds			: out std_logic_vector(4 downto 0);

		-- GPIO Periperal control
		--! Address for GPIO operations, 8 bits wide
		address_i		: in std_logic_vector(7 downto 0);
		--! Write enable signal for GPIO operations
		write_enable_i	: in std_logic;
		--! Read enable signal for GPIO operations
		read_enable_i	: in std_logic;
		--! Data to be written to GPIO, 8 bits wide
		data_in_i		: in std_logic_vector(7 downto 0);
		--! Data read from GPIO, 8 bits wide
		data_out_o		: out std_logic_vector(7 downto 0)
	);
end entity gpio;

architecture rtl of gpio is

	--! Debouncer counter size, set to 1 ms.
	constant DEBOUNCE_COUNTER	: positive := 27_000;

	--! Debounced joystick inputs
	signal joystick_debounced	: std_logic_vector(4 downto 0);

	--! Output register for GPIO
	signal output_reg 			: std_logic_vector(4 downto 0);

	--! Signal decoding the address for GPIO operations, high if selected
	signal is_selected			: std_logic;

begin

	--! Debounce the joystick inputs
	DEBOUNCE_JOYSTICK : for i in joystick'left downto joystick'right generate
		DEBOUNCER_ENTITY : entity work.debouncer
			generic map (
				DEBOUNCE_COUNTER_MAX => DEBOUNCE_COUNTER
			)
			port map (
				clk => clk,
				reset => reset,
				in_raw => joystick(i),
				deb_en => '1',  -- Always enabled for joystick debouncing
				debounced => joystick_debounced(i),
				released => open,
				pressed => open
		);
	end generate;

	is_selected <= '1' when address_i = PERIPHERAL_ADDRESS else '0';
	
	data_out_o <= "000" & joystick_debounced when is_selected = '1' and read_enable_i = '1' else
				(others => '0');  -- Default to zero if not reading

	leds <= output_reg;

	--! GPIO output register logic
	GPIO_OUT_REG : process(clk, reset) is
	begin
		if rising_edge(clk) then
			if reset = '1' then
				output_reg <= (others => '0');
			else
				output_reg <= output_reg;

				if is_selected = '1' and write_enable_i = '1' then
					-- Write to GPIO output register
					output_reg <= data_in_i(4 downto 0);
				end if;
			end if;
		end if;
	end process GPIO_OUT_REG;

end architecture;