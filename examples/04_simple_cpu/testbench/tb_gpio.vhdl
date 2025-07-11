-- Dependency: testbench/mock_debouncer.vhdl, src/peripherals/gpio.vhdl

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_gpio is
end entity tb_gpio;

architecture behavioral of tb_gpio is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant PERIPHERAL_ADDRESS : std_logic_vector(7 downto 0) := x"A0";
    constant DEBOUNCE_SIM_CYCLES : integer := 3;  -- Reduced for simulation
    
    -- Signals
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal joystick      : std_logic_vector(4 downto 0) := (others => '0');
    signal leds          : std_logic_vector(4 downto 0);
    signal address_i     : std_logic_vector(7 downto 0) := (others => '0');
    signal write_enable_i: std_logic := '0';
    signal read_enable_i : std_logic := '0';
    signal data_in_i     : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out_o    : std_logic_vector(7 downto 0);
    
    -- Test control
    signal tb_finished     : boolean := false;

begin
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2 when not tb_finished else '0';
    
    -- GPIO instance with reduced debounce cycles for simulation
    DUT: entity work.gpio(rtl)
        generic map (
            PERIPHERAL_ADDRESS => PERIPHERAL_ADDRESS
        )
        port map (
            clk            => clk,
            reset          => reset,
            joystick       => joystick,
            leds           => leds,
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
            signal output : std_logic_vector;
            expected : std_logic_vector;
            msg : string
        ) is
        begin
            wait for 1 ns;
            if output /= expected then
                report "Error: " & msg & " - Expected: " & to_hstring(expected) & 
                       ", Got: " & to_hstring(output) severity error;
                error_count := error_count + 1;
            end if;
        end procedure;
        
        -- Wait for debounce cycles
        procedure wait_debounce is
        begin
            for i in 1 to DEBOUNCE_SIM_CYCLES loop
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
        check_output(leds, "00000", "LEDs should reset to 0");
        
        -- Test Case 2: Basic LED write operation
        report "Test Case 2: Basic LED write";
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= "00011011";  -- Only lower 5 bits matter
        write_enable_i <= '1';
        wait until rising_edge(clk);
        write_enable_i <= '0';
        check_output(leds, "11011", "LEDs should update on write");
        
        -- Test Case 3: LED write retention
        report "Test Case 3: LED retention";
        address_i <= x"00";  -- Wrong address, acting like we're accessing a different peripheral
        data_in_i <= "11100000";
        write_enable_i <= '1';
        wait until rising_edge(clk);
        write_enable_i <= '0';
        check_output(leds, "11011", "LEDs should retain previous value");
        
        -- Test Case 4: Basic joystick read
        report "Test Case 4: Basic joystick read";
        joystick <= "10101";
        wait_debounce;  -- Wait for debounce to stabilize
        
        address_i <= PERIPHERAL_ADDRESS;
        read_enable_i <= '1';
        wait until rising_edge(clk);
        check_output(data_out_o, "00010101", "Should read joystick value");
        read_enable_i <= '0';
        
        -- Test Case 5: Address selection
        report "Test Case 5: Address selection";
        address_i <= x"FF";  -- Wrong address, acting like we're accessing a different peripheral
        read_enable_i <= '1';
        wait until rising_edge(clk);
        check_output(data_out_o, x"00", "Should output 0 for wrong address");
        read_enable_i <= '0';
        
        -- Test Case 6: Debounced input stability
        report "Test Case 6: Debounced input stability";
        joystick <= "11010";
        wait_debounce;
        joystick <= "00000";  -- Glitch within debounce period
        wait until rising_edge(clk);
        joystick <= "11010";  -- Back to stable value
        wait_debounce;
        
        address_i <= PERIPHERAL_ADDRESS;
        read_enable_i <= '1';
        wait until rising_edge(clk);
        check_output(data_out_o, "00011010", "Should maintain debounced value");
        read_enable_i <= '0';
        
        -- Test Case 7: Output register clear
        report "Test Case 7: Output register clear";
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        check_output(leds, "00000", "Reset should clear LEDs");
        
        -- Final report
        tb_finished <= true;
        report "Test complete. Errors detected: " & integer'image(error_count);
        wait;
    end process test_process;
    
end architecture behavioral;
