-- Dependency: src/peripherals/delay.vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_delay is
end entity tb_delay;

architecture behavioral of tb_delay is

    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant DELAY_CYCLES : positive := 5;  -- Reduced for simulation
    constant PERIPHERAL_ADDRESS : std_logic_vector(7 downto 0) := x"30";

    -- Signals
    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';
    signal address_i      : std_logic_vector(7 downto 0) := (others => '0');
    signal write_enable_i : std_logic := '0';
    signal read_enable_i  : std_logic := '0';
    signal data_in_i      : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out_o     : std_logic_vector(7 downto 0);

    -- Test control
    signal tb_finished    : boolean := false;

begin

    -- Clock generation
    clk <= not clk after CLK_PERIOD/2 when not tb_finished else '0';

    -- Delay instance with reduced delay cycles for simulation
    DUT: entity work.delay(rtl)
        generic map (
            DELAY_CYCLES => DELAY_CYCLES,
            PERIPHERAL_ADDRESS => PERIPHERAL_ADDRESS
        )
        port map (
            clk            => clk,
            reset          => reset,
            address_i      => address_i,
            write_enable_i => write_enable_i,
            read_enable_i  => read_enable_i,
            data_in_i      => data_in_i,
            data_out_o     => data_out_o
        );

    -- Test process
    test_process: process
    	variable error_count : integer := 0;

        -- Helper procedure to check output
        procedure check_output(
            expected : in std_logic_vector(7 downto 0);
            msg : in string
        ) is
        begin
            wait for 1 ns;
            if data_out_o /= expected then
                report "Error: " & msg & " - Expected: " & to_hstring(expected) & 
                       ", Got: " & to_hstring(data_out_o) severity error;
                error_count := error_count + 1;
            end if;
        end procedure;

        -- Wait for N clock cycles
        procedure wait_cycles(n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

    begin
        -- Initialize
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);

        -- Test Case 1: Reset functionality
        report "Test Case 1: Reset functionality";
        address_i <= PERIPHERAL_ADDRESS;
        read_enable_i <= '1';
        check_output(x"00", "Counter should reset to 0");
        read_enable_i <= '0';

        -- Test Case 2: Basic write operation
        report "Test Case 2: Basic write";
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= x"05";
        write_enable_i <= '1';
        wait until rising_edge(clk);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"05", "Counter should update after write");
        read_enable_i <= '0';

        -- Test Case 3: Delay counting mechanism
        report "Test Case 3: Delay counting";
        -- Counter should decrement after DELAY_CYCLES + 1 cycles
        wait_cycles(DELAY_CYCLES);
        read_enable_i <= '1';
        check_output(x"05", "Counter should not change before delay completes");

        wait until rising_edge(clk);  -- Complete the delay cycle
        check_output(x"04", "Counter should decrement after delay");
        read_enable_i <= '0';

        -- Test Case 4: Multiple delay cycles
        report "Test Case 4: Multiple delays";
        wait_cycles(DELAY_CYCLES);
        read_enable_i <= '1';
        wait until rising_edge(clk);
        check_output(x"03", "Counter should decrement after second delay");
        read_enable_i <= '0';

        -- Test Case 5: Write during countdown
        report "Test Case 5: Write during countdown";
        wait_cycles(DELAY_CYCLES - 1);  -- Almost at decrement point
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= x"03";
        write_enable_i <= '1';
        wait until rising_edge(clk);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"03", "Write should reset counter during countdown");

        -- Verify counter doesn't decrement immediately after reset
        wait_cycles(DELAY_CYCLES);
        check_output(x"03", "Counter should not decrement immediately after write");
        wait until rising_edge(clk);
        check_output(x"02", "Counter should decrement after full delay cycle");
        read_enable_i <= '0';

        -- Test Case 6: Counter saturation at zero
        report "Test Case 6: Counter saturation";
        -- Set counter to 1
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= x"01";
        write_enable_i <= '1';
        wait until rising_edge(clk);
        write_enable_i <= '0';

        -- Wait for it to decrement to 0
        wait_cycles(DELAY_CYCLES);
        read_enable_i <= '1';
        wait until rising_edge(clk);
        check_output(x"00", "Counter should reach 0");

        -- Verify it stays at 0
        wait_cycles(3 * DELAY_CYCLES);
        check_output(x"00", "Counter should stay at 0");
        read_enable_i <= '0';

        -- Test Case 7: Address selection
        report "Test Case 7: Address selection";
        -- Valid address
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= x"AA";
        write_enable_i <= '1';
        wait until rising_edge(clk);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"AA", "Valid address should work");

        -- Invalid address
        address_i <= x"FF";
		wait for 1 ns;  -- Allow time for address change
        check_output(x"00", "Invalid address should return 0");
		wait for 1 ns;  -- Allow time for read to complete
        read_enable_i <= '0';

        -- Final report
        tb_finished <= true;
        report "Test complete. Errors detected: " & integer'image(error_count);
        wait;
    end process test_process;

end architecture behavioral;