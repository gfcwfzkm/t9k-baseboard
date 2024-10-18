-- TerosHDL Documentation:
--! @title Rotary Encoder with Debouncer
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! date 18.10.2024
--! @brief This module decodes a rotary encoder with debouncer.
--!
--! This module debounces the signals coming from an rotary encoder and returns
--! either a CW or CCW signal depending on the direction of rotation. The module
--! also debounces the push button signal of the rotary encoder.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rotary_enc is
	generic (
		--! Number of clock cycles to wait before the input signal is considered stable
		DEBOUNCE_COUNTER_MAX : positive := 5000
	);
	port (
		--! Clock input
		clk			: in std_logic;
		--! Async reset input, active high
		reset		: in std_logic;

		--! Raw signal A from the rotary encoder
		raw_a		: in std_logic;
		--! Raw signal B from the rotary encoder
		raw_b		: in std_logic;
		--! Raw push button signal from the rotary encoder
		raw_sw		: in std_logic;

		--! CW signal output, active for one clock cycle
		rotenc_ccw	: out std_logic;
		--! CCW signal output, active for one clock cycle
		rotenc_cw	: out std_logic;
		--! Push button signal output, active for one clock cycle
		rotenc_sw	: out std_logic
	);
end entity rotary_enc;

architecture rtl of rotary_enc is
	--! Pressed A signal and debounced B signal
	signal a_pressed, b_debounced : std_logic;
begin

	rotenc_cw <= '1' when a_pressed = '1' and b_debounced = '0' else '0';
	rotenc_ccw <= '1' when a_pressed = '1' and b_debounced = '1' else '0';

	--! Debouncer for the rotary encoder A signal
	DEBOUNCE_A : entity work.debouncer
  		generic map (
			DEBOUNCE_COUNTER_MAX => DEBOUNCE_COUNTER_MAX
		)
  		port map (
			clk => clk,
			reset => reset,
			in_raw => raw_a,
			deb_en => '1',
			debounced => open,
			released => open,
			pressed => a_pressed
  	);

	--! Debouncer for the rotary encoder B signal
	DEBOUNCE_B : entity work.debouncer
		generic map (
			DEBOUNCE_COUNTER_MAX => DEBOUNCE_COUNTER_MAX
		)	
		port map (
			clk => clk,
			reset => reset,
			in_raw => raw_b,
			deb_en => '1',
			debounced => b_debounced,
			released => open,
			pressed => open
	);

	--! Debouncer for the push button signal
	DEBOUNCE_SW : entity work.debouncer
		generic map (
			DEBOUNCE_COUNTER_MAX => DEBOUNCE_COUNTER_MAX
		)	
		port map (
			clk => clk,
			reset => reset,
			in_raw => raw_sw,
			deb_en => '1',
			debounced => open,
			released => open,
			pressed => rotenc_sw
	);

end architecture;