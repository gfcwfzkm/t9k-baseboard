-- TEROSHDL Documentation:
--! @title Swiss Flag Test Image Generator
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 19.03.2024
--! @brief Generates a test image with the Swiss flag and color strips for video output.
--!
--! Developed for the BFH oscilloscope project.
--!
--! This module generates a test image for video output, which includes the Swiss flag
--! and color strips at the top and bottom of the screen. The image is drawn in a 1280x720
--! resolution, with the Swiss flag centered in the middle of the screen.
--! The color strips are 160 pixels wide and display a sequence of colors.
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
		clk		: in  std_logic;
		--! Synchronous Reset signal (active-high)
		reset	: in  std_logic;

		--! RGB Color Output
		r,g,b	: out std_logic;
		--! Horizontal Sync signal (active-high)
		hsync	: out std_logic;
		--! Vertical Sync signal (active-high)
		vsync	: out std_logic;
		--! Data Enable signal (active-high)
		de		: out std_logic
	);
end entity video;

architecture rtl of video is
	--! Constants for the color strip test
	constant testbar : positive := 160;

	--! X coordinates of the currently drawn pixel
	signal draw_x : unsigned(11 downto 0);
	--! Y coordinates of the currently drawn pixel
	signal draw_y : unsigned(10 downto 0);
	--! Active signal to indicate if the current pixel is being drawn
	signal draw_active : std_logic;

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
			if draw_y < 200 then				
				if (draw_x < testbar) then
					r_next <= '1';
				elsif (draw_x < (testbar * 2)) then
					g_next <= '1';
				elsif (draw_x < (testbar * 3)) then
					r_next <= '1';
					g_next <= '1';
				elsif (draw_x < (testbar * 4)) then
					b_next <= '1';
				elsif (draw_x < (testbar * 5)) then
					r_next <= '1';
					b_next <= '1';
				elsif (draw_x < (testbar * 6)) then
					g_next <= '1';
					b_next <= '1';
				elsif (draw_x < (testbar * 7)) then
					r_next <= '1';
					g_next <= '1';
					b_next <= '1';
				else
					null; -- No color in the last spot of the strip
				end if;
			elsif draw_y > 520 then
				if (draw_x < testbar) then
					null; -- No color in the last spot of the strip
				elsif (draw_x < (testbar * 2)) then
					r_next <= '1';
					g_next <= '1';
					b_next <= '1';
				elsif (draw_x < (testbar * 3)) then
					g_next <= '1';
					b_next <= '1';
				elsif (draw_x < (testbar * 4)) then
					r_next <= '1';
					b_next <= '1';
				elsif (draw_x < (testbar * 5)) then
					b_next <= '1';
				elsif (draw_x < (testbar * 6)) then
					r_next <= '1';
					g_next <= '1';
				elsif (draw_x < (testbar * 7)) then
					g_next <= '1';
				else
					r_next <= '1';					
				end if;
			else

				-- Swiss flag, quadratic, 320 x 320
				-- with the proportions: 6, 7, 6, 7, 6

				-- Render the red background in this area
				if ((draw_x > 480) and (draw_x < 800)) then
					r_next <= '1';
				end if;

				-- Draw the white foreground of the flag
				if ((draw_y >= 260) and (draw_y <= 460)) then
					if ((draw_x > 610) and (draw_x < 670)) then
						g_next <= '1';
						b_next <= '1';
					end if;
					
					if ((draw_y >= 330) and (draw_y <= 390)) then
						if ((draw_x > 540) and (draw_x < 740)) then
							g_next <= '1';
							b_next <= '1';
						end if;
					end if;
				end if;

			end if;
		end if;
	end process CHFLAG;

	--! Video Timing Generator, configured for 1280x720p@60Hz
	VIDEO_TIMING_GENERATOR : entity work.vtgen
		generic map (
			H_VISIBLE => 1280,	--! Horizontal resolution
			H_FPORCH => 110,	--! Horizontal Front Porch
			H_SYNC => 40,		--! Horizontal Sync Pulse
			H_BPORCH => 220,	--! Horizontal Back Porch
			V_VISIBLE => 720,	--! Vertical resolution
			V_FPORCH => 5,		--! Vertical Front Porch
			V_SYNC => 5,		--! Vertical Sync Pulse
			V_BPORCH => 20		--! Vertical Back Porch,
		)
		port map (
			clk => clk,
			reset => reset,
			disp_active => draw_active,
			disp_x => draw_x,
			disp_y => draw_y,
			hdmi_vsync => vsync_next,
			hdmi_hsync => hsync_next,
			hdmi_de => de_next
	);

end architecture;