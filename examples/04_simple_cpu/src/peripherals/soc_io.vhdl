-- TEROSHDL Documentation:
--! @title Overture System-on-Chip I/O Module
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 13.07.2025
--! @brief A simple SoC I/O module for the Overture CPU.
--!
--! This module integrates various peripherals for the Overture CPU, including RAM, GPIO, and
--! delay counters. It provides a unified interface for I/O operations, allowing the CPU to
--! interact with these peripherals through a common address space.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soc_io is
    port (
        --! Clock input, synchronous with the system clock
        clk                     : in std_logic;
        --! Reset input, active high
        reset                   : in std_logic;
        
        --! Joystick input - 0: down, 1: right, 2: up, 3: left, 4: center
        joystick                : in std_logic_vector(4 downto 0);

        --! UART receive input
        uart_rx                 : in std_logic;

        --! UART transmit output
        uart_tx                 : out std_logic;

        --! Parallel LEDs output, active-high
        leds                    : out std_logic_vector(4 downto 0);

        --! Digital, serial RGB LED output
        rgbled_ser              : out std_logic;

        --! Address for I/O operations, 8 bits wide
        io_address              : in std_logic_vector(7 downto 0);
        --! Data to be written to I/O, 8 bits wide
        io_data_write           : in std_logic_vector(7 downto 0);
        --! Data read from I/O, 8 bits wide
        io_data_read            : out std_logic_vector(7 downto 0);
        --! Write enable signal for I/O operations
        io_data_write_enable    : in std_logic;
        --! Read enable signal for I/O operations
        io_data_read_enable     : in std_logic
    );
end entity soc_io;

architecture rtl of soc_io is

    signal io_data_from_ram         : std_logic_vector(7 downto 0);
    signal io_data_from_gpio        : std_logic_vector(7 downto 0);
    signal io_data_from_delay_us    : std_logic_vector(7 downto 0);
    signal io_data_from_delay_ms    : std_logic_vector(7 downto 0);
    signal io_data_from_delay_s     : std_logic_vector(7 downto 0);

begin

    --! Assign the read data from all the peripherals to the io_data, all OR'ed together
    --! so make sure inactive peripherals return 0.
    io_data_read <= io_data_from_ram or io_data_from_gpio or io_data_from_delay_us or
                    io_data_from_delay_ms or io_data_from_delay_s;

    --! 16 bytes of RAM for the Overture CPU, accessible via the I/O interface
    OVERTURE_RAM : entity work.ram(rtl)
        generic map (
            PERIPHERAL_ADDRESS  => x"00",   -- Start address for RAM
            RAM_SIZE            => 16,
            WORD_WIDTH          => 8
        )
        port map (
            clk_i               => clk,
            reset_i             => reset,
            address_i           => io_address,
            write_enable_i      => io_data_write_enable,
            read_enable_i       => io_data_read_enable,
            data_in_i           => io_data_write,
            data_out_o          => io_data_from_ram
    );

    --! LEDs output, switches input
    OVERTURE_GPIO : entity work.gpio(rtl)
        generic map (
            PERIPHERAL_ADDRESS  => x"10"    -- Start address for GPIO
        )
        port map (
            clk                 => clk,
            reset               => reset,
            joystick            => joystick,
            leds                => leds,
            address_i           => io_address,
            write_enable_i      => io_data_write_enable,
            read_enable_i       => io_data_read_enable,
            data_in_i           => io_data_write,
            data_out_o          => io_data_from_gpio
    );

    --! Delay us counter
    OVERTURE_DELAY_US : entity work.delay(rtl)
        generic map (
            DELAY_CYCLES        => 27,
            PERIPHERAL_ADDRESS  => x"11"
        )
        port map (
            clk                 => clk,
            reset               => reset,
            address_i           => io_address,
            write_enable_i      => io_data_write_enable,
            read_enable_i       => io_data_read_enable,
            data_in_i           => io_data_write,
            data_out_o          => io_data_from_delay_us
    );

    --! Delay ms counter
    OVERTURE_DELAY_MS : entity work.delay(rtl)
        generic map (
            DELAY_CYCLES        => 27_000,
            PERIPHERAL_ADDRESS  => x"12"
        )
        port map (
            clk                 => clk,
            reset               => reset,
            address_i           => io_address,
            write_enable_i      => io_data_write_enable,
            read_enable_i       => io_data_read_enable,
            data_in_i           => io_data_write,
            data_out_o          => io_data_from_delay_ms
    );

    --! Delay s counter
    OVERTURE_DELAY_S : entity work.delay(rtl)
        generic map (
            DELAY_CYCLES        => 27_000_000,
            PERIPHERAL_ADDRESS  => x"13"
        )
        port map (
            clk                 => clk,
            reset               => reset,
            address_i           => io_address,
            write_enable_i      => io_data_write_enable,
            read_enable_i       => io_data_read_enable,
            data_in_i           => io_data_write,
            data_out_o          => io_data_from_delay_s
    );
    
    --! TODO Serial RGB LED output at some point
    --! Nothing special. Current idea: Three registers for each color channel and
    --! after a write, the color is sent out serially. Any other write to the
    --! RGB LED registers is not lost but just ignored until the
    --! transmission is finished.
    rgbled_ser <= '0'; --! Placeholder for RGB LED output, can be implemented later

    --! TODO UART FIFO Tx/Rx at some point
    --! Idea: Provide two addresses to read the FIFO status, one for Tx and one for Rx.
    --! The FIFO status shows the amount of *free* space - thus if it's zero, the FIFO is full.
    --! Checks against zero are very simple in the CPU, so that eases up things!
    --! A third address provides the actual access to the FIFO. A read 
    --! reads from the Rx FIFO, a write writes to the Tx FIFO.
    uart_tx <= uart_rx; --! Directly connect UART RX to TX for simplicity

end architecture;