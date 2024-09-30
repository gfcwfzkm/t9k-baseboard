-- TEROSHDL Documentation:
--! @title RGB-LED to Serial Interface
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 19.09.2024
--! @brief Sends 24-bit RGB-LED data to a serial interface
--!
--! This module sends 24-bit RGB-LED data to a serial interface. The data is sent
--! in the following order: Red, Green, Blue. The module is written as generic as
--! possible to allow for easy configuration of the timing parameters, for different
--! RGB-LEDs.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rgb_to_ser is
	generic (
		--! Clock Frequency given to this module in MHz
		CLK_FREQ_MHZ	: positive;
		--! High-Time of the LED signal in ns for a logical 0
		T0H_TIMING_NS	: positive := 350;
		--! High-Time of the LED signal in ns for a logical 1
		T1H_TIMING_NS	: positive := 1360;
		--! Low-Time of the LED signal in ns for a logical 0
		T0L_TIMING_NS	: positive := 1360;
		--! Low-Time of the LED signal in ns for a logical 1
		T1L_TIMING_NS	: positive := 350;
		--! Reset-Time of the LED signal in ns
		TRESET_TIMING_NS: positive := 50_000
	);
	port (
		--! f_fpga clock speed
		clk				: in std_logic;
		--! Asynchronous reset (active high)
		reset			: in std_logic;
		
		--! Send reset to the RGB-LED
		send_reset		: in std_logic;
		--! Send data to the RGB-LED
		send_data		: in std_logic;
		
		--! RGB-LED color values: Red
		red				: in std_logic_vector(7 downto 0);
		--! RGB-LED color values: Green
		green			: in std_logic_vector(7 downto 0);
		--! RGB-LED color values: Blue
		blue			: in std_logic_vector(7 downto 0);

		--! Idle signal (high when idle)
		idle			: out std_logic;
		--! Serial data signal to the RGB-LED
		rgbled_serdata	: out std_logic
	);
end entity rgb_to_ser;

architecture rtl of rgb_to_ser is
	type state_type is (STATE_IDLE, SET_BIT_HIGH, WAIT_BIT_HIGH,
		SET_BIT_LOW, WAIT_BIT_LOW, RESET_TRANSMISSION);
	
	CONSTANT COLORDATA_WIDTH : integer := 24;
	CONSTANT T0H_CYCLES : integer := integer(T0H_TIMING_NS * CLK_FREQ_MHZ);
	CONSTANT T1H_CYCLES : integer := integer(T1H_TIMING_NS * CLK_FREQ_MHZ);
	CONSTANT T0L_CYCLES : integer := integer(T0L_TIMING_NS * CLK_FREQ_MHZ);
	CONSTANT T1L_CYCLES : integer := integer(T1L_TIMING_NS * CLK_FREQ_MHZ);
	CONSTANT TRESET_CYCLES : integer := integer(TRESET_TIMING_NS * CLK_FREQ_MHZ);

	signal state_reg, state_next					: state_type := STATE_IDLE;
	signal colordata_reg, colordata_next			: std_logic_vector(COLORDATA_WIDTH-1 downto 0) := (others => '0');
	signal bit_counter_reg, bit_counter_next		: unsigned(integer(ceil(log2(real(COLORDATA_WIDTH)))) downto 0) := (others => '0');
	signal cycle_counter_reg, cycle_counter_next	: unsigned(integer(ceil(log2(real(TRESET_CYCLES)))) downto 0) := (others => '0');
begin

	REGS : process (clk, reset) begin
		if reset = '1' then
			state_reg <= STATE_IDLE;
			colordata_reg <= (others => '0');
			bit_counter_reg <= (others => '0');
			cycle_counter_reg <= (others => '0');
		elsif rising_edge(clk) then
			state_reg <= state_next;
			colordata_reg <= colordata_next;
			bit_counter_reg <= bit_counter_next;
			cycle_counter_reg <= cycle_counter_next;
		end if;
	end process REGS;

	NSL : process (state_reg, colordata_reg, bit_counter_reg, cycle_counter_reg, send_reset, send_data) begin
		state_next <= state_reg;
		colordata_next <= colordata_reg;
		bit_counter_next <= bit_counter_reg;
		cycle_counter_next <= cycle_counter_reg;

		-- Default output values
		idle <= '0';
		rgbled_serdata <= '0';

		case state_reg is
			when STATE_IDLE =>
				idle <= '1';
				bit_counter_next <= to_unsigned(COLORDATA_WIDTH, bit_counter_next'length);
				if (send_reset = '1') then
					state_next <= RESET_TRANSMISSION;
					cycle_counter_next <= to_unsigned(TRESET_CYCLES, cycle_counter_next'length);
				elsif (send_data = '1') then
					state_next <= SET_BIT_HIGH;
					colordata_next <= red & green & blue;
				end if;
			when RESET_TRANSMISSION =>
				if (cycle_counter_reg = 0) then
					state_next <= STATE_IDLE;
				else
					cycle_counter_next <= cycle_counter_reg - 1;
					state_next <= RESET_TRANSMISSION;
				end if;
			when SET_BIT_HIGH =>
				rgbled_serdata <= '1';
				bit_counter_next <= bit_counter_reg - 1;
				if (colordata_reg(COLORDATA_WIDTH-1) = '0') then
					cycle_counter_next <= to_unsigned(T0H_CYCLES, cycle_counter_next'length);
				else
					cycle_counter_next <= to_unsigned(T1H_CYCLES, cycle_counter_next'length);
				end if;
				state_next <= WAIT_BIT_HIGH;
			when WAIT_BIT_HIGH =>
				rgbled_serdata <= '1';
				if (cycle_counter_reg = 0) then
					state_next <= SET_BIT_LOW;
				else
					cycle_counter_next <= cycle_counter_reg - 1;
					state_next <= WAIT_BIT_HIGH;
				end if;
			when SET_BIT_LOW =>
				bit_counter_next <= bit_counter_reg - 1;
				colordata_next <= colordata_reg(COLORDATA_WIDTH-2 downto 0) & '0';
				if (colordata_reg(COLORDATA_WIDTH-1) = '0') then
					cycle_counter_next <= to_unsigned(T0L_CYCLES, cycle_counter_next'length);
				else
					cycle_counter_next <= to_unsigned(T1L_CYCLES, cycle_counter_next'length);
				end if;
				state_next <= WAIT_BIT_LOW;
			when WAIT_BIT_LOW =>
				if (cycle_counter_reg = 0) then
					if (bit_counter_reg = 0) then
						state_next <= STATE_IDLE;
					else
						state_next <= SET_BIT_HIGH;
					end if;
				else
					cycle_counter_next <= cycle_counter_reg - 1;
					state_next <= WAIT_BIT_LOW;
				end if;
			when others =>
				null;
		end case;
	end process NSL;

end architecture;