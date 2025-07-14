-- TEROSHDL Documentation:
--! @title Delay Module
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 11.07.2025
--! @brief A simple delay module with configurable delay cycles.
--!
--! This module implements a simple delay mechanism that counts down from a specified number of clock cycles.
--! Writing to the delay register sets the counter to the specified value.
--! The counter decrements each clock cycle until it reaches zero, at the speed of the specified delay cycles.
--! Once the counter reaches zero, it stays there until a new value is written.
--!
--! This module allows for a simple delay mechanism in the overture cpu. Simply set
--! the amount of time to wait by writing here, then read the counter value
--! and compare it to zero to see if the delay is done.
--! 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity delay is
    generic (
        --! Delay in clock cycles
        DELAY_CYCLES : positive;
        --! IO Peripheral Address
        PERIPHERAL_ADDRESS : std_logic_vector(7 downto 0)
    );
    port (
        --! Clock input, synchronous with the system clock
        clk   : in std_logic;
        --! Reset input, synchronous, active high
        reset : in std_logic;
        
        --! Address for delay operations, 8 bits wide
        address_i : in std_logic_vector(7 downto 0);
        --! Write enable signal for delay operations
        write_enable_i : in std_logic;
        --! Read enable signal for delay operations
        read_enable_i : in std_logic;
        --! Input data to be written to the delay counter
        data_in_i : in std_logic_vector(7 downto 0);
        --! Output data read from the delay counter, async read
        data_out_o : out std_logic_vector(7 downto 0)
    );
end entity delay;

architecture rtl of delay is

    constant DELAY_WIDTH    : positive := integer(ceil(log2(real(DELAY_CYCLES))));
    constant MAX_DELAY      : unsigned(DELAY_WIDTH-1 downto 0) := to_unsigned(DELAY_CYCLES, DELAY_WIDTH);

    signal delay_reg, delay_next        : unsigned(DELAY_WIDTH-1 downto 0) := (others => '0');
    signal counter_reg, counter_next    : unsigned(7 downto 0) := (others => '0');

    signal is_selected                  : std_logic;
    signal internal_read_enable         : std_logic;
    signal internal_write_enable        : std_logic;

begin

    CLKREG : process(clk, reset) is
    begin
        if rising_edge(clk) then
            if reset = '1' then
                delay_reg <= (others => '0');
                counter_reg <= (others => '0');
            else
                delay_reg <= delay_next;
                counter_reg <= counter_next;
            end if;
        end if;
    end process CLKREG;

    --! Check if the current address is within the delay peripheral range
    is_selected <= '1' when address_i = PERIPHERAL_ADDRESS else '0';

    --! Set the internal read and write enables based on the selected address
    internal_read_enable <= read_enable_i and is_selected;
    internal_write_enable <= write_enable_i and is_selected;

    --! Output the counter value when read is enabled
    data_out_o <= std_logic_vector(counter_reg) when internal_read_enable = '1' else
                  (others => '0');  -- Default to zero if not reading

    NSL : process(delay_reg, counter_reg, internal_write_enable, data_in_i) is
    begin

        delay_next <= delay_reg;
        counter_next <= counter_reg;

        if internal_write_enable = '1' then
            --! If write is enabled, set the delay register and counter register
            delay_next <= MAX_DELAY;  -- Set to maximum delay
            counter_next <= unsigned(data_in_i);  -- Set counter to input data
        else
            if delay_reg > 0 then
                --! If delay is active, decrement the delay register
                delay_next <= delay_reg - 1;
            else
                delay_next <= MAX_DELAY;  -- Reset delay to maximum when it reaches zero

                --! Decrement the counter
                --! If the counter has reached zero, stay there
                if counter_reg > 0 then
                    counter_next <= counter_reg - 1;
                end if;
            end if;
        end if;

    end process NSL;

end architecture;