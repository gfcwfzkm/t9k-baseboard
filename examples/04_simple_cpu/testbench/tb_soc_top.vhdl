-- Dependency: testbench/mock_debouncer.vhdl, src/peripherals/delay.vhdl, src/peripherals/gpio.vhdl, src/peripherals/ram.vhdl, src/peripherals/soc_io.vhdl, src/overture/alu.vhdl, src/overture/barrel_shifter.vhdl, src/overture/condition.vhdl, src/overture/execute.vhdl, src/overture/decode.vhdl, src/overture/fetch.vhdl, src/overture/registers.vhdl, src/overture/write_back.vhdl, src/overture/overture.vhdl, src/rom.vhdl, src/soc_top.vhdl
--! @title SoC Top Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 09.07.2025
--! @brief Testbench for the SoC Top Level
--!
--! This testbench verifies the functionality of the SoC Top Level.
--! It serves as a simulator for the entire SoC system.
--!
--! The simulation aborts when the CPU halts or a timeout occurs.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_soc_top is
end tb_soc_top;

architecture behavior of tb_soc_top is

    -- Inputs
    signal clk                  : std_logic := '0';
    signal reset_unsanitized    : std_logic := '1';  -- Active-low reset
    signal joystick_unsanitized : std_logic_vector(4 downto 0) := (others => '1'); -- Inactive (active-low)
    signal uart_rx_unsanitized  : std_logic := '1';  -- UART idle state

    -- Outputs
    signal uart_tx      : std_logic;
    signal leds_n       : std_logic_vector(4 downto 0);
    signal cpu_halted_n : std_logic;
    signal rgbled_ser   : std_logic;

    -- Clock period definitions (27 MHz)
    constant clk_period : time := 37.037 ns; -- 1/27e9 ≈ 37.037 ns
    
    -- Timeout condition
    constant timeout : time := 10000 ms;

    -- Testbench status
    signal tb_finished : boolean := false;

begin

    -- Instantiate the SoC Top component
    DUT: entity work.soc_top(rtl)
        port map (
            clk                     => clk,
            reset_unsanitized       => reset_unsanitized,
            joystick_unsanitized    => joystick_unsanitized,
            uart_rx_unsanitized     => uart_rx_unsanitized,
            uart_tx                 => uart_tx,
            leds_n                  => leds_n,
            cpu_halted_n            => cpu_halted_n,
            rgbled_ser              => rgbled_ser
        );

    -- Clock generation
    clk <= not clk after clk_period/2 when not tb_finished else '0';

    -- Stimulus process with timeout
    stim_proc: process
    begin
        -- Apply reset (active-low)
        reset_unsanitized <= '0';
        wait for clk_period * 5;  -- Hold reset for 5 cycles
        reset_unsanitized <= '1';  -- Release reset

        report "Reset released, starting simulation..." severity note;

        -- Wait for either halt signal or timeout
        wait until cpu_halted_n'event for timeout;
        --wait for timeout;
        
        -- Check which condition terminated the wait
        if cpu_halted_n = '0' then
            report "CPU halted (" & std_logic'image(cpu_halted_n) & ")! Simulation stopped." severity note;
        else
            report "Timeout reached! Simulation stopped." severity note;
        end if;

        -- Report the LED state
        report "LEDs state: " & to_string(leds_n) severity note;
        report "UART TX: " & std_logic'image(uart_tx) severity note;
        report "RGB LED Serial Output: " & std_logic'image(rgbled_ser) severity note;


        -- Wait for one more clock cycle to ensure all signals are stable
        wait for clk_period;  -- Allow one more clock cycle to process the halt signal
        report "Final state after halt: CPU halted = " & std_logic'image(cpu_halted_n) severity note;

        -- Indicate testbench completion
        tb_finished <= true;
        wait;
    end process;

end architecture;