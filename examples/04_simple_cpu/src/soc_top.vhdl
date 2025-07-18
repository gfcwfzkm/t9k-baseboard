
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soc_top is
    port (
        --! Clock input, 27 MHz on the Tang Nano 9K
        clk                     : in std_logic;
        --! Reset input, active low
        reset_unsanitized       : in std_logic;

        --! Joystick inputs, active low
        joystick_unsanitized    : in std_logic_vector(4 downto 0);
        --! UART receive unsanitized input
        uart_rx_unsanitized     : in std_logic;

        --! UART transmit output
        uart_tx                 : out std_logic;
        --! Parellel LEDs output, active-low
        leds_n                  : out std_logic_vector(4 downto 0);
        --! CPU halt signal, active low
        cpu_halted_n            : out std_logic;
        --! Digital, serial RGB LED output
        rgbled_ser              : out std_logic
    );
end entity soc_top;

architecture rtl of soc_top is

    type t_sanitizing_array is array (0 to 2) of std_logic_vector(6 downto 0);
    signal sanitizing_reg : t_sanitizing_array := (others => (others => '0'));

    signal reset                : std_logic;

    signal memory_data          : std_logic_vector(7 downto 0);
    signal memory_address       : std_logic_vector(7 downto 0);
    signal io_address           : std_logic_vector(7 downto 0);
    signal io_data_from_cpu     : std_logic_vector(7 downto 0);
    signal io_data_to_cpu       : std_logic_vector(7 downto 0);
    signal io_data_write_enable : std_logic;
    signal io_data_read_enable  : std_logic;

    signal leds                 : std_logic_vector(4 downto 0);
    signal cpu_halted           : std_logic;
    signal joystick             : std_logic_vector(4 downto 0);
    signal uart_rx              : std_logic;

begin

    -- Assign sanitized signals
    reset       <= sanitizing_reg(2)(0);
    joystick    <= sanitizing_reg(2)(5 downto 1);
    uart_rx     <= sanitizing_reg(2)(6);

    -- Assign outputs, invert if needed for active-low outputs
    leds_n          <= not leds;
    cpu_halted_n    <= not cpu_halted;

    --! Sanitize the input signals by sending them through a two-stage register chain
    INPUT_SANITIZER : process(clk)
    begin
        if rising_edge(clk) then
            sanitizing_reg(0) <= uart_rx_unsanitized & 
                                 not joystick_unsanitized &
                                 not reset_unsanitized;
            sanitizing_reg(1) <= sanitizing_reg(0);
            sanitizing_reg(2) <= sanitizing_reg(1);
        end if;
    end process;

    --! The simple 8-bit Overture CPU from the game Turing Complete
    OVERTURE_CPU : entity work.overture(rtl)
        port map (
            clk_i                   => clk,
            reset_i                 => reset,
            memory_data_i           => memory_data,
            memory_address_o        => memory_address,
            io_address_o            => io_address,
            io_data_read_i          => io_data_to_cpu,
            io_data_write_o         => io_data_from_cpu,
            io_data_write_enable_o  => io_data_write_enable,
            io_data_read_enable_o   => io_data_read_enable,
            cpu_halted_o            => cpu_halted
    );

    --! Basic, asynchronous ROM holding the program code
    OVERTURE_ROM : entity work.rom(rtl)
        port map (
            address_i               => memory_address,
            data_out_o              => memory_data
    );

    --! IO map for the Overture CPU, handling RAM, joystick inputs, UART, LEDs, and RGB LED
    OVERTURE_IOMAP : entity work.soc_io(rtl)
        port map (
            clk                     => clk,
            reset                   => reset,
            joystick                => joystick,
            uart_rx                 => uart_rx,
            uart_tx                 => uart_tx,
            leds                    => leds,
            rgbled_ser              => rgbled_ser,
            io_address              => io_address,
            io_data_write           => io_data_from_cpu,
            io_data_read            => io_data_to_cpu,
            io_data_write_enable    => io_data_write_enable,
            io_data_read_enable     => io_data_read_enable
    );

end architecture;