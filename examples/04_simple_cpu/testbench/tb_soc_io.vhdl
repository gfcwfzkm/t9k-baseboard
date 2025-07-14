-- Dependency: testbench/mock_debouncer.vhdl, src/peripherals/delay.vhdl, src/peripherals/gpio.vhdl, src/peripherals/ram.vhdl, src/peripherals/soc_io.vhdl
--! @title SoC I/O Peripheral Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 09.07.2025
--! @brief Testbench for the SoC I/O peripheral
--!
--! This testbench verifies the functionality of the SoC I/O peripheral.
--! It includes tests for RAM access, GPIO operations, and delay peripherals.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_soc_io is
end entity tb_soc_io;

architecture tb of tb_soc_io is
    -- Constants
    constant CLK_PERIOD : time := 37 ns;  -- 27 MHz clock
    constant DELAY_US_CYCLES : positive := 27;   -- Reduced for simulation
    constant DELAY_MS_CYCLES : positive := 27_000;  -- Reduced for simulation
    constant DELAY_S_CYCLES  : positive := 27_000_000;  -- Reduced for simulation
    
    -- Signals
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';
    signal joystick  : std_logic_vector(4 downto 0) := (others => '0');
    signal leds      : std_logic_vector(4 downto 0);
    signal address   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_write: std_logic_vector(7 downto 0) := (others => '0');
    signal data_read : std_logic_vector(7 downto 0);
    signal write_en  : std_logic := '0';
    signal read_en   : std_logic := '0';
    
    -- Test control
    signal tb_finished : boolean := false;
begin
    -- Instantiate DUT with reduced delay cycles
    DUT: entity work.soc_io(rtl)
        port map (
            clk                     => clk,
            reset                   => reset,
            joystick                => joystick,
            leds                    => leds,
            uart_rx                 => '0',
            uart_tx                 => open,
            rgbled_ser              => open,
            io_address              => address,
            io_data_write           => data_write,
            io_data_read            => data_read,
            io_data_write_enable    => write_en,
            io_data_read_enable     => read_en
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2 when not tb_finished else '0';

    -- Main test process
    process
        variable seed1, seed2 : positive := 1;
        variable rand_val     : real;
        variable rand_addr    : integer;
        variable rand_data    : std_logic_vector(7 downto 0);
        variable rand_op      : integer;
        variable tests_passed : integer := 0;
        variable tests_failed : integer := 0;
    begin
        -- Initial reset
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;

        --------------------------------------------
        -- Test 1: RAM Access (0x00-0x0F)
        --------------------------------------------
        report "Starting RAM test...";
        -- Write to RAM addresses
        for i in 0 to 15 loop
            address    <= std_logic_vector(to_unsigned(i, 8));
            data_write <= std_logic_vector(to_unsigned(i, 8));
            write_en   <= '1';
            wait for CLK_PERIOD;
        end loop;
        write_en <= '0';
        wait for CLK_PERIOD;

        -- Read back from RAM
        for i in 0 to 15 loop
            address <= std_logic_vector(to_unsigned(i, 8));
            read_en <= '1';
            wait for CLK_PERIOD;
            if data_read = std_logic_vector(to_unsigned(i, 8)) then
                tests_passed := tests_passed + 1;
            else
                tests_failed := tests_failed + 1;
                report "RAM read mismatch at 0x" & to_hstring(address) 
                       & " Expected: " & to_hstring(to_unsigned(i,8)) 
                       & " Got: " & to_hstring(data_read)
                       severity error;
            end if;
        end loop;
        read_en <= '0';
        wait for CLK_PERIOD;

        -- Test invalid RAM address (0x20)
        address <= x"20";
        read_en <= '1';
        wait for CLK_PERIOD;
        if data_read = x"00" then
            tests_passed := tests_passed + 1;
        else
            tests_failed := tests_failed + 1;
            report "Invalid RAM address not zero" severity error;
        end if;
        read_en <= '0';

        --------------------------------------------
        -- Test 2: GPIO Access (0x10)
        --------------------------------------------
        report "Starting GPIO test...";
        -- Set joystick inputs (debounced after 3 cycles)
        joystick <= "10101";
        wait for CLK_PERIOD * 5;  -- Allow debounce

        -- Read joystick state
        address <= x"10";
        read_en <= '1';
        wait for CLK_PERIOD;
        if data_read(4 downto 0) = "10101" then
            tests_passed := tests_passed + 1;
        else
            tests_failed := tests_failed + 1;
            report "GPIO read mismatch" severity error;
        end if;
        read_en <= '0';

        -- Write to LEDs
        address    <= x"10";
        data_write <= "00011111";
        write_en   <= '1';
        wait for CLK_PERIOD;
        write_en <= '0';
        wait for CLK_PERIOD;
        if leds = "11111" then
            tests_passed := tests_passed + 1;
        else
            tests_failed := tests_failed + 1;
            report "LED output mismatch" severity error;
        end if;

        --------------------------------------------
        -- Test 3: Delay Peripherals
        --------------------------------------------
        -- Test delay_us (0x11)
        address    <= x"11";
        data_write <= x"01";  -- Set counter to 1
        write_en   <= '1';
        wait for CLK_PERIOD;
        write_en <= '0';
        wait for CLK_PERIOD * (DELAY_US_CYCLES - 1);
        
        read_en <= '1';
        wait for CLK_PERIOD;
        if data_read = x"01" then
            tests_passed := tests_passed + 1;
        else
            tests_failed := tests_failed + 1;
            report "delay_us counter mismatch (pre-zero)" severity error;
        end if;
        
        wait for CLK_PERIOD;
        if data_read = x"00" then
            tests_passed := tests_passed + 1;
        else
            tests_failed := tests_failed + 1;
            report "delay_us counter not zero" severity error;
        end if;
        read_en <= '0';

        --------------------------------------------
        -- Final report
        --------------------------------------------
        report "Tests completed: " & integer'image(tests_passed) & " passed, " 
               & integer'image(tests_failed) & " failed";
        tb_finished <= true;
        wait;
    end process;
end architecture tb;
