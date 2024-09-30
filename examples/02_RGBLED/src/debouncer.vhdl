-- TEROSHDL Documentation:
--! @title Button Debouncer
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 29.03.2024
--! @brief Debounces a button input signal
--!
--! This module debounces a button input signal. The debouncing is done by
--! counting the number of consecutive cycles the button is in the same state.
--! If the button is pressed for DEBOUNCE_CNT cycles, the state is set to '1'.
--! If the button is released for DEBOUNCE_CNT cycles, the state is set to '0'.
--! The debouncer also generates events for the button being pressed or released.
--! These events are one cycle wide and are synchronized to the clock.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity debouncer is
	generic (
		--! Number of cycles until the button is considered pressed/released
		DEBOUNCE_CNT		: positive	:= 255;
		--! Clockdivider - counts the clock cycles before the button press is sampled
		CLKPERIOD 			: positive	:= 10;
		--! Active-State of the button (logic-level when pressed)
		BUTTON_ACTIVE_LEVEL	: std_logic	:= '0'
	);
	port (
		--! f_fpga clock speed
		clk			: in std_logic;
		--! Asynchronous reset (active high)
		reset		: in std_logic;

		--! Bouncy button input
		button		: in std_logic;
		--! Debounced button state
		state		: out std_logic;
		--! Button pressed event
		released	: out std_logic;
		--! Button released event
		pressed		: out std_logic
	);
end entity debouncer;

architecture rtl of debouncer is
	--! Button counter register - increased when the button is pressed, decreased when the button is released
	signal btnCounter_reg	: unsigned(integer(ceil(log2(real(DEBOUNCE_CNT)))) downto 0) := (others => '0');
	--! Clock Counter register to reduce the sample rate of the bouncy button
	signal clkCounter_reg	: unsigned(integer(ceil(log2(real(DEBOUNCE_CNT)))) downto 0) := (others => '0');
	--! Register holding the last valid state of the button. Updated when btnCounter_reg reaches 0 or DEBOUNCE_CNT
	signal dbState_reg		: std_logic := '0';
	signal released_reg		: std_logic := '0';
	signal pressed_reg		: std_logic := '0';
begin
	
	state <= dbState_reg;
	released <= released_reg;
	pressed <= pressed_reg;

	--! Button Debouncing Process
	DEBOUNCER : process(clk, reset) is	
	begin
		-- Reset the debouncer
		if reset = '1' then
			btnCounter_reg <= (others => '0');
			clkCounter_reg <= (others => '0');
			dbState_reg <= '0';			
			released_reg <= '0';
			pressed_reg <= '0';
		elsif rising_edge(clk) then
			released_reg <= '0';
			pressed_reg <= '0';

			-- Clock divider
			CLKCNT : if unsigned(clkCounter_reg) < CLKPERIOD then
				clkCounter_reg <= clkCounter_reg + 1;
			else
				clkCounter_reg <= to_unsigned(0, clkCounter_reg'length);
			end if CLKCNT;

			-- Button debouncing by incrementing / decrementing a counter when 
			-- the button is pressed / released
			BUTTON_DEBOUNCING : if unsigned(clkCounter_reg) = CLKPERIOD then
				BUTTON_READING : if button = BUTTON_ACTIVE_LEVEL then
					OVERFLOW_PREVENTION : if btnCounter_reg /= DEBOUNCE_CNT then
						btnCounter_reg <= btnCounter_reg + 1;
					end if OVERFLOW_PREVENTION;
				else
					UNDERFLOW_PREVENTION : if btnCounter_reg /= 0 then
						btnCounter_reg <= btnCounter_reg - 1;
					end if UNDERFLOW_PREVENTION;
				end if BUTTON_READING;
			end if BUTTON_DEBOUNCING;

			-- Generate a short pulse when the button just got pressed
			EVENT_PRESSED : if btnCounter_reg = DEBOUNCE_CNT and dbState_reg = '0' then
				pressed_reg <= '1';
			end if;

			-- Generate a short pulse when the button just got released
			EVENT_RELEASED : if btnCounter_reg = 0 and dbState_reg = '1' then
				released_reg <= '1';
			end if;

			-- Update the general button state
			STATE_UPDATE : if btnCounter_reg = DEBOUNCE_CNT then
				dbState_reg <= '1';
			elsif btnCounter_reg = 0 then
				dbState_reg <= '0';
			end if STATE_UPDATE;
		end if;
	end process DEBOUNCER;

end architecture;