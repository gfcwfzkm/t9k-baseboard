-- TerosHDL Documentation:
--! @title HSV to RGB Converter
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 18.10.2024
--! @brief This module converts a HSV color value to a RGB color value.
--!
--! This module converts a HSV color value to a RGB color value, but only for the
--! hue value. The saturation and value are fixed to 100%. The hue value must be
--! between 0 and 767.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity hsv_to_rgb is
	port (
		--! HSV color value to convert, between 0 and 767
		hsv_hue			: in unsigned(9 downto 0);

		--! RGB color value - Red
		rgb_red			: out unsigned(7 downto 0);
		--! RGB color value - Green
		rgb_green		: out unsigned(7 downto 0);
		--! RGB color value - Blue
		rgb_blue		: out unsigned(7 downto 0)
	);
end entity hsv_to_rgb;

architecture rtl of hsv_to_rgb is
	constant RGBVALUE_MAX : unsigned(7 downto 0) := x"ff";
	signal hsv_xored : unsigned(7 downto 0);
begin

	hsv_xored <= hsv_hue(7 downto 0) xor RGBVALUE_MAX;

	with hsv_hue(9 downto 8) select rgb_red <=
		hsv_xored			when "00",
		(others => '0')		when "01",
		hsv_hue(7 downto 0)	when "10",
		(others => '0')		when others;

	with hsv_hue(9 downto 8) select rgb_green <=
		hsv_hue(7 downto 0) when "00",
		hsv_xored			when "01",
		(others => '0')		when "10",
		(others => '0')		when others;
	
	with hsv_hue(9 downto 8) select rgb_blue <=
		(others => '0')		when "00",
		hsv_hue(7 downto 0)	when "01",
		hsv_xored			when "10",
		(others => '0')		when others;

end architecture;