library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity debouncer_tb is end;

architecture bench of debouncer_tb is
	constant clk_periode : time := 1 ns;

	signal dut_abtn, dut_bbtn, dut_astate, dut_bstate, dut_apressed, dut_bpressed, 
		dut_areleased, dut_breleased, dut_rst : std_logic := '0';


	signal clk : std_logic := '0';
	signal tb_finished : boolean := false;
begin
	dut_bbtn <= not dut_abtn;

	-- active-high test
	debouncer_A : entity work.debouncer
  		generic map (
			DEBOUNCE_CNT => 7,
			CLKPERIOD => 2,
			BUTTON_ACTIVE_LEVEL => '1'
  		)
  		port map (
			clk => clk,
			reset => dut_rst,
			button => dut_abtn,
			state => dut_astate,
			released => dut_areleased,
			pressed => dut_apressed
	);

	-- Active-low test
	debouncer_B : entity work.debouncer
  		generic map (
			DEBOUNCE_CNT => 7,
			CLKPERIOD => 2,
			BUTTON_ACTIVE_LEVEL => '0'
  		)
  		port map (
			clk => clk,
			reset => dut_rst,
			button => dut_bbtn,
			state => dut_bstate,
			released => dut_breleased,
			pressed => dut_bpressed
	);

	-- Generate Clock and finish the simulation if tb_finished is True
	CLKGEN : process begin
		if (tb_finished = false) then
			clk <= '1'; wait for clk_periode;
			clk <= '0'; wait for clk_periode;
		else
			wait;
		end if;
	end process CLKGEN;
	
	TESTING : process is
		variable count : integer := 0;
	begin 
		report "Start of automated test";
		dut_abtn <= '0';
		
		dut_rst <= '1';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		dut_rst <= '0';		
		wait until rising_edge(clk);
		wait until falling_edge(clk);

		wait for 10 ns;

		-- Press
		wait until rising_edge(clk);
		dut_abtn <= '1';
		wait for 5 ns;
		wait until rising_edge(clk);
		dut_abtn <= '0';
		wait for 3 ns;
		wait until rising_edge(clk);
		dut_abtn <= '1';
		wait for 50 ns;

		-- Release
		dut_abtn <= '0';
		wait for 1 ns;
		dut_abtn <= '1';
		wait for 2 ns;
		dut_abtn <= '0';
		wait for 3 ns;
		dut_abtn <= '1';
		wait for 5 ns;
		dut_abtn <= '0';
		wait for 50 ns;

		-- Press
		dut_abtn <= '1';
		wait for 2 ns;
		dut_abtn <= '0';
		wait for 3 ns;
		dut_abtn <= '1';
		wait for 5 ns;
		dut_abtn <= '0';
		wait for 2 ns;
		dut_abtn <= '1';
		wait for 50 ns;

		tb_finished <= True;
		wait;

	end process TESTING;		
end architecture;