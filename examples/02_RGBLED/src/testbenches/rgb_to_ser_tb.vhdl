library ieee;
context ieee.ieee_std_context;
use ieee.math_real.all;

library std;
use std.textio.all;

entity rgb_to_ser_tb is
end entity rgb_to_ser_tb;

architecture rtl of rgb_to_ser_tb is
	constant CLK_FREQ_MHZ : positive := 27;
	constant CLK_HALF_CYCLE : time := 18518.5185185185 ps;

	signal tb_finished : boolean := false;
	signal tb_clk : std_logic := '0';
	signal tb_reset : std_logic := '1';
	signal tb_send_reset : std_logic := '0';
	signal tb_send_data : std_logic := '0';
	signal tb_red : std_logic_vector(7 downto 0) := (others => '0');
	signal tb_green : std_logic_vector(7 downto 0) := (others => '0');
	signal tb_blue : std_logic_vector(7 downto 0) := (others => '0');
	signal tb_idle : std_logic;
	signal tb_rgbled_serdata : std_logic;

begin

	rgb_to_ser_inst : entity work.rgb_to_ser
		generic map (
			CLK_FREQ_MHZ => CLK_FREQ_MHZ
		)
		port map (
			clk				=> tb_clk,
			reset			=> tb_reset,
			send_reset		=> tb_send_reset,
			send_data		=> tb_send_data,
			red				=> tb_red,
			green			=> tb_green,
			blue			=> tb_blue,
			idle			=> tb_idle,
			rgbled_serdata	=> tb_rgbled_serdata
	);

	tb_clk <= not tb_clk after CLK_HALF_CYCLE when not tb_finished else '0';

	STIMULI : process is
	begin
		wait for 1 ns;
		tb_reset <= '0';
		tb_blue <= x"FF";
		tb_green <= x"FF";
		tb_red <= x"FF";
		tb_send_data <= '1';
		wait until rising_edge(tb_clk);
		tb_send_data <= '0';

		wait until falling_edge(tb_clk);
		wait until tb_idle = '1';

		tb_blue <= x"00";
		tb_green <= x"00";
		tb_red <= x"0F";
		tb_send_data <= '1';
		wait until rising_edge(tb_clk);
		tb_send_data <= '0';

		wait until falling_edge(tb_clk);
		wait until tb_idle = '1';

		tb_finished <= true;
		wait;
	end process STIMULI;
end architecture;