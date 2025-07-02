library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity top is 
    port (
        clk   : in std_logic;	--! Clock input @ 27 MHz
        rst_n : in std_logic;	--! Active low reset
        
        leds  : out std_logic_vector(5 downto 0)	--! Output port for the LEDs
    );
end top;

architecture RTL of top is
    
    --! Increase counter_reg every 6_750_000 clock cycles
    constant CLK_DIV_CNT : positive := 6_750_000;
    --! Width of the CLK_DIV_CNT constant
    constant count_width : integer := integer(ceil(log2(real(CLK_DIV_CNT))));
    
    signal counter_reg : unsigned(5 downto 0) := (others => '0');
    signal clkdiv_reg  : unsigned(count_width-1 downto 0) := (others => '0');

begin

    --! Assign the counter value to the LEDs - NOT gate is used as the LEDs are active low
    leds <= not std_logic_vector(counter_reg);

    --! Counter and clock divider
    COUNTER : process (clk, rst_n) begin
        if rst_n = '0' then
            -- Reset the counter and clock divider
            counter_reg <= (others => '0');
            clkdiv_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Increment the clock divider
            clkdiv_reg <= clkdiv_reg + 1;

            -- Check if the clock divider has reached the desired value
            if clkdiv_reg = to_unsigned(CLK_DIV_CNT, count_width) then
                -- Reset the clock divider and increment the counter
                clkdiv_reg <= (others => '0');
                counter_reg <= counter_reg + 1;
            end if;
        end if;
    end process COUNTER;

end architecture RTL;