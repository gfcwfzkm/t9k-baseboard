-- TEROSHDL Documentation:
--! @title Swiss Flag Test Image Generator
--! @author Pascal G. (gfcwfzkm)
--! @version 1.1
--! @date 19.03.2024
--! @brief Generates a test image with the Swiss flag and color strips for video output.
--!
--! Developed for the BFH oscilloscope project.
--!
--! This module generates a test image for video output, which includes the Swiss flag
--! and color strips at the top and bottom of the screen. While the video timing generator
--! generates a video resolution of 1920x1080p, only half that resolution is actually used
--! by the test image generator, resulting in an actual resolution of 960x540p, with a 
--! Swiss flag in the center of the size 320x320, and a color bar at the top and bottom
--!
--! Only the MSB of the RGB color signals are used, as this is a 3-bit color output.
--!
--! Proportions of the swiss flag are from wikimedia:
--! https://commons.wikimedia.org/wiki/File:Swiss_Flag_Specifications.svg
--! ![Swiss Flag Proportions](https://upload.wikimedia.org/wikipedia/commons/6/61/Swiss_Flag_Specifications.svg)
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity video is
    port (
        --! Pixel Clock
        clk     : in  std_logic;
        --! Synchronous Reset signal (active-high)
        reset   : in  std_logic;

        --! RGB Color Output
        r,g,b   : out std_logic;
        --! Horizontal Sync signal (active-high)
        hsync   : out std_logic;
        --! Vertical Sync signal (active-high)
        vsync   : out std_logic;
        --! Data Enable signal (active-high)
        de      : out std_logic
    );
end entity video;

architecture rtl of video is
    --! Constants for the color strip test
    constant testbar : positive := 120;

    --! X coordinates of the currently drawn pixel
    signal draw_x : unsigned(9 downto 0);
    --! Y coordinates of the currently drawn pixel
    signal draw_y : unsigned(9 downto 0);
    --! Active signal to indicate if the current pixel is being drawn
    signal draw_active : std_logic;

    signal video_x : unsigned(12 downto 0);
    signal video_y : unsigned(11 downto 0);

    --! Video Color Output Registers
    signal r_next, r_reg, g_next, g_reg, b_next, b_reg : std_logic;
    --! Video Control / Timing Output Registers
    signal de_next, de_reg, hsync_next, hsync_reg, vsync_next, vsync_reg : std_logic;
begin
    -- Register to output assignments
    r <= r_reg;
    g <= g_reg;
    b <= b_reg;
    de <= de_reg;
    hsync <= hsync_reg;
    vsync <= vsync_reg;

    draw_x <= video_x(10 downto 1);
    draw_y <= video_y(10 downto 1);

    --! Register Process
    REGBANK : process (reset, clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                r_reg <= '0';
                g_reg <= '0';
                b_reg <= '0';
                de_reg <= '0';
                hsync_reg <= '0';
                vsync_reg <= '0';
            else
                r_reg <= r_next;
                g_reg <= g_next;
                b_reg <= b_next;
                de_reg <= de_next;
                hsync_reg <= hsync_next;
                vsync_reg <= vsync_next;
            end if;
        end if;
    end process;

    --! Next-State-Logic, generating the swiss flag
    CHFLAG : process (draw_x, draw_y, draw_active)
    begin
        r_next <= '0';
        g_next <= '0';
        b_next <= '0';
        
        if (draw_active = '1') then
            -- Render a test color strip at the top and bottom
            -- The test color strip is 7 colors, each 160 pixels wide
            -- The bottom strip follows a different order than the top strip
            -- Uses GrayCode (bgr <= 000) to create the color bar
            if draw_y < 110 then
                if (draw_x < testbar) then
                    null;
                elsif (draw_x < (testbar * 2)) then
                    r_next <= '1';
                elsif (draw_x < (testbar * 3)) then
                    r_next <= '1';
                    g_next <= '1';
                elsif (draw_x < (testbar * 4)) then
                    g_next <= '1';
                elsif (draw_x < (testbar * 5)) then
                    g_next <= '1';
                    b_next <= '1';
                elsif (draw_x < (testbar * 6)) then
                    g_next <= '1';
                    b_next <= '1';
                    r_next <= '1';
                elsif (draw_x < (testbar * 7)) then
                    r_next <= '1';
                    b_next <= '1';
                else
                    b_next <= '1';
                end if;
            elsif draw_y > 430 then
                if (draw_x < testbar) then
                    b_next <= '1';
                elsif (draw_x < (testbar * 2)) then
                    r_next <= '1';
                    b_next <= '1';
                elsif (draw_x < (testbar * 3)) then
                    g_next <= '1';
                    b_next <= '1';
                    r_next <= '1';
                elsif (draw_x < (testbar * 4)) then
                    g_next <= '1';
                    b_next <= '1';
                elsif (draw_x < (testbar * 5)) then
                    g_next <= '1';
                elsif (draw_x < (testbar * 6)) then
                    r_next <= '1';
                    g_next <= '1';
                elsif (draw_x < (testbar * 7)) then
                    r_next <= '1';
                else
                    null;
                end if;
            else

                -- Swiss flag, quadratic, 320 x 320
                -- with the proportions: 6, 7, 6, 7, 6

                -- Render the red background in this area
                if ((draw_x > 320) and (draw_x < 640)) then
                    r_next <= '1';
                end if;

                -- Draw the white foreground of the flag
                if ((draw_y >= 170) and (draw_y <= 370)) then
                    if ((draw_x > 450) and (draw_x < 510)) then
                        g_next <= '1';
                        b_next <= '1';
                    end if;
                    
                    if ((draw_y >= 240) and (draw_y <= 300)) then
                        if ((draw_x > 380) and (draw_x < 580)) then
                            g_next <= '1';
                            b_next <= '1';
                        end if;
                    end if;
                end if;

            end if;
        end if;
    end process CHFLAG;

    --! Video Timing Generator, configured for 1920x1080p@30Hz
    VIDEO_TIMING_GENERATOR : entity work.vtgen
        generic map (
            H_VISIBLE => 1920,  --! Horizontal resolution
            H_FPORCH  => 88,    --! Horizontal Front Porch
            H_SYNC    => 44,    --! Horizontal Sync Pulse
            H_BPORCH  => 148,   --! Horizontal Back Porch
            V_VISIBLE => 1080,  --! Vertical resolution
            V_FPORCH  => 4,     --! Vertical Front Porch
            V_SYNC    => 5,     --! Vertical Sync Pulse
            V_BPORCH  => 36     --! Vertical Back Porch,
        )
        port map (
            clk         => clk,
            reset       => reset,
            disp_active => draw_active,
            disp_x      => video_x,
            disp_y      => video_y,
            hdmi_vsync  => vsync_next,
            hdmi_hsync  => hsync_next,
            hdmi_de     => de_next
    );

end architecture;