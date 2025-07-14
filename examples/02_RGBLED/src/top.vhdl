-- TerosHDL Documentation:
--! @title RGB-LED and Rotary Encoder Project
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! date 18.10.2024
--! @brief This project demonstrates the usage of a rotary encoder to change the color of an RGB-LED.
--!
--! The rotary encoder is used to change the color of an RGB-LED by rotating it. The color is changed by
--! increasing or decreasing the hue value of the HSV color space. The HSV color space is then converted
--! to the RGB color space and the resulting color is displayed on the RGB-LED.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
    port (
        --! 27 MHz clock input
        clk         : in std_logic;
        --! Active low reset input, routed to BTN1/S1
        rst_n       : in std_logic;

        --! Rotary encoder raw signal A
        rot_raw_a   : in std_logic;
        --! Rotary encoder raw signal B
        rot_raw_b   : in std_logic;

        --! RGB-LED serial data output
        rgbdata     : out std_logic
    );
end entity top;

architecture rtl of top is

    --! State machine states
    type state_type is (
        WAITFOR_PRESS,              --! Wait for rotary encoder press when the RGB-LED is idle
        SENDING_RGBDATA,            --! Send RGB data to the RGB-LED
        RESETTING_LED_TRANSMISSION  --! Reset the RGB-LED transmission
    );
    
    --! RGB-LED start transmission signal
    signal ser_rgbled_start : std_logic;
    --! RGB-LED reset transmission signal
    signal ser_rgbled_reset : std_logic;
    --! RGB-LED idle signal (high when the RGB-LED is ready for a new instruction)
    signal ser_rgbled_idle : std_logic;
    --! RGB values for the RGB-LED
    signal rgb_red, rgb_green, rgb_blue : std_logic_vector(7 downto 0);

    --! Rotary encoder signals, increment is CW, decrement is CCW
    signal rotary_inc, rotary_dec : std_logic;

    --! State machine register
    signal state_reg, state_next : state_type;

    --! Reset signal, active high
    signal reset : std_logic;
begin

    -- Invert the reset signal to be active high
    reset <= not rst_n;

    --! State Machine Register Process
    CLKREG : process(clk, reset) is
    begin
        if reset = '1' then
            state_reg <= WAITFOR_PRESS;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process CLKREG;

    --! State Machine - Next-State-Logic
    NSL : process(state_reg, rotary_inc, rotary_dec, ser_rgbled_idle) is
    begin
        -- Register the next state
        state_next <= state_reg;

        -- Default values for the RGB-LED signals
        ser_rgbled_reset <= '0';
        ser_rgbled_start <= '0';

        case state_reg is
            when WAITFOR_PRESS =>
                -- Wait for the RGB-LED to be idle
                if ser_rgbled_idle = '1' then
                    -- If the rotary encoder is rotated, switch to the next state
                    if rotary_inc = '1' or rotary_dec = '1' then
                        state_next <= SENDING_RGBDATA;
                    end if;
                end if;
            when SENDING_RGBDATA =>
                -- Send the RGB data to the RGB-LED
                -- Can't do it in the previous state because the RGB value might not ready yet
                ser_rgbled_start <= '1';
                state_next <= RESETTING_LED_TRANSMISSION;
            when RESETTING_LED_TRANSMISSION =>
                -- Reset the RGB-LED transmission after sending the RGB data
                if ser_rgbled_idle = '1' then
                    ser_rgbled_reset <= '1';
                    state_next <= WAITFOR_PRESS;
                end if;
        end case;
    end process NSL;

    --! RGB-LED to Serial Interface
    rgb_to_ser_inst : entity work.rgb_to_ser
          generic map (
            CLK_FREQ_MHZ => 27
          )
          port map (
            clk             => clk,
            reset           => reset,
            send_reset      => ser_rgbled_reset,
            send_data       => ser_rgbled_start,
            red             => rgb_red,
            green           => rgb_green,
            blue            => rgb_blue,
            idle            => ser_rgbled_idle,
            rgbled_serdata  => rgbdata
      );

    --! Rotary Encoder Module
    rotary_enc_inst : entity work.rotary_enc
        generic map (
            DEBOUNCE_COUNTER_MAX => 5000
        )
          port map (
            clk         => clk,
            reset       => reset,
            raw_a       => not rot_raw_a,
            raw_b       => not rot_raw_b,
            raw_sw      => '0',
            rotenc_ccw  => rotary_dec,
            rotenc_cw   => rotary_inc,
            rotenc_sw   => open
    );
    
    --! Cycle Colors Module
    cycle_colors_inst : entity work.cycle_colors
        port map (
            clk     => clk,
            reset   => reset,
            inc_col => rotary_inc,
            dec_col => rotary_dec,
            red     => rgb_red,
            green   => rgb_green,
            blue    => rgb_blue
    );
    
end architecture;