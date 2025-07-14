-- Dependency: src/peripherals/ram.vhdl
--! @title RAM Peripheral Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 09.07.2025
--! @brief Testbench for the RAM peripheral
--!
--! This testbench verifies the functionality of the RAM peripheral.
--! It includes tests for basic read/write operations, address boundaries, and enable combinations.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_ram is
end entity tb_ram;

architecture behavioral of tb_ram is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant PERIPHERAL_ADDRESS : std_logic_vector(7 downto 0) := x"10";
    constant RAM_SIZE : integer := 16;
    constant WORD_WIDTH : integer := 8;
    constant NUM_RANDOM_TESTS : integer := 100;
    
    -- Signals
    signal clk_i          : std_logic := '0';
    signal reset_i        : std_logic := '0';
    signal address_i      : std_logic_vector(7 downto 0) := (others => '0');
    signal write_enable_i : std_logic := '0';
    signal read_enable_i  : std_logic := '0';
    signal data_in_i      : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal data_out_o     : std_logic_vector(WORD_WIDTH-1 downto 0);
    
    -- Test control
    signal tb_finished      : boolean := false;
    
begin
    -- Clock generation
    clk_i <= not clk_i after CLK_PERIOD/2 when not tb_finished else '0';
    
    -- RAM instance
    DUT: entity work.ram(rtl)
        generic map (
            PERIPHERAL_ADDRESS => PERIPHERAL_ADDRESS,
            RAM_SIZE => RAM_SIZE,
            WORD_WIDTH => WORD_WIDTH
        )
        port map (
            clk_i          => clk_i,
            reset_i        => reset_i,
            address_i      => address_i,
            write_enable_i => write_enable_i,
            read_enable_i  => read_enable_i,
            data_in_i      => data_in_i,
            data_out_o     => data_out_o
        );
    
    -- Test process
    test_process: process
        variable seed1, seed2 : positive := 1;
        variable rand_real : real;
        variable rand_int : integer;
        variable expected_data : std_logic_vector(WORD_WIDTH-1 downto 0);
        variable error_count : integer := 0;
        
        -- Helper procedure to check output
        procedure check_output(
            expected : in std_logic_vector(WORD_WIDTH-1 downto 0);
            msg : in string
        ) is
        begin
            wait until falling_edge(clk_i);
            wait for 1 ns;
            if data_out_o /= expected then
                report "Error: " & msg & " - Expected: " & to_hstring(expected) & 
                       ", Got: " & to_hstring(data_out_o) & " at address " & to_string(address_i) severity error;
                error_count := error_count + 1;
            end if;
        end procedure;
        
    begin
        -- Initialize
        reset_i <= '1';
        wait until rising_edge(clk_i);
        reset_i <= '0';
        wait until rising_edge(clk_i);
        
        -- Test Case 1: Reset functionality
        report "Starting Test Case 1: Reset functionality";
        reset_i <= '1';
        address_i <= PERIPHERAL_ADDRESS;
        read_enable_i <= '1';
        wait until rising_edge(clk_i);
        check_output((others => '0'), "Reset should output zeros");
        reset_i <= '0';
        wait until rising_edge(clk_i);
        
        -- Test Case 2: Basic write/read
        report "Starting Test Case 2: Basic write/read";
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= x"AA";
        write_enable_i <= '1';
        read_enable_i <= '0';
        wait until rising_edge(clk_i);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"AA", "Basic read after write");
        
        -- Test Case 3: Address boundary tests
        report "Starting Test Case 3: Address boundaries";
        -- First address
        address_i <= PERIPHERAL_ADDRESS;
        data_in_i <= x"55";
        write_enable_i <= '1';
        read_enable_i <= '0';
        wait until rising_edge(clk_i);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"55", "First address write/read");
        
        -- Last address
        address_i <= std_logic_vector(unsigned(PERIPHERAL_ADDRESS) + RAM_SIZE - 1);
        data_in_i <= x"F0";
        write_enable_i <= '1';
        read_enable_i <= '0';
        wait until rising_edge(clk_i);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"F0", "Last address write/read");
        
        -- Test Case 4: Non-selected address
        report "Starting Test Case 4: Non-selected address";
        address_i <= std_logic_vector(unsigned(PERIPHERAL_ADDRESS) - 1);
        read_enable_i <= '1';
        check_output((others => '0'), "Address below range");
        
        address_i <= std_logic_vector(unsigned(PERIPHERAL_ADDRESS) + RAM_SIZE);
        check_output((others => '0'), "Address above range");
        
        -- Test Case 5: Write/read enable combinations
        report "Starting Test Case 5: Enable combinations";
        address_i <= PERIPHERAL_ADDRESS;
        read_enable_i <= '0';
        write_enable_i <= '0';
        check_output((others => '0'), "No enables should output 0");
        
        data_in_i <= x"33";
        write_enable_i <= '1';
        wait until rising_edge(clk_i);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"33", "Write without read enable followed by read");
        
        -- Test Case 6: Out of bounds write/read 
        report "Starting Test Case 7: Out of bounds write/read";
        -- First address
        address_i <= std_logic_vector(unsigned(PERIPHERAL_ADDRESS) + to_unsigned(RAM_SIZE, 8));  -- Out of bounds
        data_in_i <= x"55";
        write_enable_i <= '1';
        read_enable_i <= '0';
        wait until rising_edge(clk_i);
        write_enable_i <= '0';
        read_enable_i <= '1';
        check_output(x"00", "Out of bounds write/read");

        -- Final report
        tb_finished <= true;
        report "Test complete. Errors detected: " & integer'image(error_count);
        wait;
    end process test_process;
end architecture behavioral;