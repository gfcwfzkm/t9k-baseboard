-- TerosHDL Documentation:
--! @title Cycle Colors
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 18.10.2024
--! @brief Cycles through the colors of the RGB-LED
--!
--! This module cycles through the colors of the RGB-LED by incrementing or 
--! decrementing a counter, which is then converted to a RGB value using the
--! hsv_to_rgb module. The counter is incremented or decremented by 4, to
--! allow for a faster transition between the colors.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity cycle_colors is
    port (
        --! Clock signal
        clk   : in std_logic;
        --! Reset signal (active high, asynchronous)
        reset : in std_logic;

        --! Increment the color counter
        inc_col : in std_logic;
        --! Decrement the color counter
        dec_col : in std_logic;

        --! RGB-LED color values: Red
        red   : out std_logic_vector(7 downto 0);
        --! RGB-LED color values: Green
        green : out std_logic_vector(7 downto 0);
        --! RGB-LED color values: Blue
        blue  : out std_logic_vector(7 downto 0)        
    );
end entity cycle_colors;

architecture rtl of cycle_colors is
    --! Counter for the color cycling
    signal counter_reg, counter_next : unsigned(9 downto 0) := (others => '0');

    --! RGB-LED color values
    signal rgb_red, rgb_green, rgb_blue : unsigned(7 downto 0);
begin

    --! Register Logic
    CLKREG : process(clk, reset) is
    begin
        if reset = '1' then
            counter_reg <= (others => '0');
        elsif rising_edge(clk) then
            counter_reg <= counter_next;
        end if;
    end process CLKREG;

    --! Next State Logic
    process(counter_reg, inc_col, dec_col) is
    begin
        counter_next <= counter_reg;

        --! Reset the counter if it reaches the maximum value
        if counter_reg >= to_unsigned(768, counter_reg'length) then
            counter_next <= to_unsigned(0, counter_next'length);
        end if;

        if inc_col = '1' then
            -- Increment the counter by 4, reset if it reaches the maximum value
            if counter_reg = to_unsigned(767, counter_reg'length) then
                counter_next <= to_unsigned(0, counter_next'length);
            else
                counter_next <= counter_reg + 4;
            end if;
        elsif dec_col = '1' then
            -- Decrement the counter by 4, reset if it reaches the minimum value
            if counter_reg = to_unsigned(0, counter_reg'length) then
                counter_next <= to_unsigned(767, counter_next'length);
            else
                counter_next <= counter_reg - 4;
            end if;
        end if;
    end process;

    red <= std_logic_vector(rgb_red);
    green <= std_logic_vector(rgb_green);
    blue <= std_logic_vector(rgb_blue);

    --! Convert the counter value (hue) to RGB values
    hsv_to_rgb_inst : entity work.hsv_to_rgb
        port map (
            hsv_hue     => counter_reg,
            rgb_red     => rgb_red,
            rgb_green   => rgb_green,
            rgb_blue    => rgb_blue
    );


end architecture;