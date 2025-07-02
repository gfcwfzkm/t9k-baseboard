-- TEROSHDL Documentation:
--! @title RGB-LED to Serial Interface
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 19.09.2024
--! @brief Sends 24-bit RGB-LED data to a serial interface
--!
--! This module sends 24-bit RGB-LED data to a serial interface. The data is sent
--! in the following order: Red, Green, Blue. The module is written as generic as
--! possible to allow for easy configuration of the timing parameters, for different
--! RGB-LEDs.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rgb_to_ser is
    generic (
        --! Clock Frequency given to this module in MHz
        CLK_FREQ_MHZ    : positive;
        --! High-Time of the LED signal in ns for a logical 0
        T0H_TIMING_NS   : positive := 350;
        --! High-Time of the LED signal in ns for a logical 1
        T1H_TIMING_NS   : positive := 1360;
        --! Low-Time of the LED signal in ns for a logical 0
        T0L_TIMING_NS   : positive := 1360;
        --! Low-Time of the LED signal in ns for a logical 1
        T1L_TIMING_NS   : positive := 350;
        --! Reset-Time of the LED signal in ns
        TRESET_TIMING_NS: positive := 50_000
    );
    port (
        --! f_fpga clock speed
        clk             : in std_logic;
        --! Asynchronous reset (active high)
        reset           : in std_logic;
        
        --! Send reset to the RGB-LED
        send_reset      : in std_logic;
        --! Send data to the RGB-LED
        send_data       : in std_logic;
        
        --! RGB-LED color values: Red
        red             : in std_logic_vector(7 downto 0);
        --! RGB-LED color values: Green
        green           : in std_logic_vector(7 downto 0);
        --! RGB-LED color values: Blue
        blue            : in std_logic_vector(7 downto 0);

        --! Idle signal (high when idle)
        idle            : out std_logic;
        --! Serial data signal to the RGB-LED
        rgbled_serdata  : out std_logic
    );
end entity rgb_to_ser;

architecture rtl of rgb_to_ser is
    type state_type is (
        STATE_IDLE,
        WAIT_BIT_HIGH,
        WAIT_BIT_LOW,
        RESET_TRANSMISSION
    );
    
    CONSTANT COLORDATA_WIDTH : integer := 24;
    CONSTANT T0H_CNT_TOP : integer := integer(round(real(T0H_TIMING_NS * CLK_FREQ_MHZ) / 1000.0)) - 1;
    CONSTANT T1H_CNT_TOP : integer := integer(round(real(T1H_TIMING_NS * CLK_FREQ_MHZ) / 1000.0)) - 1;
    CONSTANT T0L_CNT_TOP : integer := integer(round(real(T0L_TIMING_NS * CLK_FREQ_MHZ) / 1000.0)) - 1;
    CONSTANT T1L_CNT_TOP : integer := integer(round(real(T1L_TIMING_NS * CLK_FREQ_MHZ) / 1000.0)) - 1;
    CONSTANT TRESET_CNT_TOP : integer := integer(ceil(real(TRESET_TIMING_NS * CLK_FREQ_MHZ) / 1000.0)) - 1;

    signal color_data_arranged                      : std_logic_vector(COLORDATA_WIDTH-1 downto 0) := (others => '0');
    signal state_reg, state_next                    : state_type := STATE_IDLE;
    signal colordata_reg, colordata_next            : std_logic_vector(COLORDATA_WIDTH-1 downto 0) := (others => '0');
    signal bit_counter_reg, bit_counter_next        : unsigned(integer(ceil(log2(real(COLORDATA_WIDTH))))-1 downto 0) := (others => '0');
    signal cycle_counter_reg, cycle_counter_next    : unsigned(integer(ceil(log2(real(TRESET_CNT_TOP))))-1 downto 0) := (others => '0');
begin

    with state_reg select rgbled_serdata <=
        '1' when WAIT_BIT_HIGH,
        '0' when others;
    
    with state_reg select idle <=
        '1' when STATE_IDLE,
        '0' when others;
    
    color_data_arranged <= red & green & blue;

    REGS : process (clk, reset) begin
        if reset = '1' then
            state_reg <= STATE_IDLE;
            colordata_reg <= (others => '0');
            bit_counter_reg <= (others => '0');
            cycle_counter_reg <= (others => '0');
        elsif rising_edge(clk) then
            state_reg <= state_next;
            colordata_reg <= colordata_next;
            bit_counter_reg <= bit_counter_next;
            cycle_counter_reg <= cycle_counter_next;
        end if;
    end process REGS;

    NSL : process (state_reg, colordata_reg, bit_counter_reg, cycle_counter_reg, send_reset, send_data, color_data_arranged) begin
        state_next <= state_reg;
        colordata_next <= colordata_reg;
        bit_counter_next <= bit_counter_reg;
        cycle_counter_next <= cycle_counter_reg;

        case state_reg is
            when STATE_IDLE =>
                if (send_reset = '1') then
                    state_next <= RESET_TRANSMISSION;
                    cycle_counter_next <= to_unsigned(TRESET_CNT_TOP, cycle_counter_next'length);
                elsif (send_data = '1') then
                    bit_counter_next <= to_unsigned(COLORDATA_WIDTH-1, bit_counter_next'length);
                    colordata_next <= color_data_arranged;

                    if (color_data_arranged(COLORDATA_WIDTH-1) = '0') then
                        cycle_counter_next <= to_unsigned(T0H_CNT_TOP, cycle_counter_next'length);
                    else
                        cycle_counter_next <= to_unsigned(T1H_CNT_TOP, cycle_counter_next'length);
                    end if;

                    state_next <= WAIT_BIT_HIGH;
                end if;
            when WAIT_BIT_HIGH =>
                if (cycle_counter_reg = 0) then
                    colordata_next <= colordata_reg(COLORDATA_WIDTH-2 downto 0) & '0';
                    if (colordata_reg(COLORDATA_WIDTH-1) = '0') then
                        cycle_counter_next <= to_unsigned(T0L_CNT_TOP, cycle_counter_next'length);
                    else
                        cycle_counter_next <= to_unsigned(T1L_CNT_TOP, cycle_counter_next'length);
                    end if;

                    state_next <= WAIT_BIT_LOW;
                else
                    cycle_counter_next <= cycle_counter_reg - 1;
                end if;
            when WAIT_BIT_LOW =>
                if (cycle_counter_reg = 0) then
                    if (bit_counter_reg = 0) then
                        state_next <= STATE_IDLE;
                    else	
                        bit_counter_next <= bit_counter_reg - 1;

                        if (colordata_reg(COLORDATA_WIDTH-1) = '0') then
                            cycle_counter_next <= to_unsigned(T0H_CNT_TOP, cycle_counter_next'length);
                        else
                            cycle_counter_next <= to_unsigned(T1H_CNT_TOP, cycle_counter_next'length);
                        end if;

                        state_next <= WAIT_BIT_HIGH;
                    end if;
                else
                    cycle_counter_next <= cycle_counter_reg - 1;
                end if;
            when RESET_TRANSMISSION =>
                if (cycle_counter_reg = 0) then
                    state_next <= STATE_IDLE;
                else
                    cycle_counter_next <= cycle_counter_reg - 1;
                    state_next <= RESET_TRANSMISSION;
                end if;
            when others =>
                state_next <= STATE_IDLE;
        end case;
    end process NSL;

end architecture;