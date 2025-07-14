-- TerosHDL Documentation:
--! @title Mock Debouncer
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 09.10.2024
--! @brief Mock entity for debouncer in testbench.
--!
--! This is a mock entity for the debouncer component used in the testbench.
--! It simulates the debouncer behavior with an fixed internal counter
--! value of 3 for testing purposes.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity debouncer is
    generic (
        --! The value here as no effect as the logic is locked to a fixed value of three
        DEBOUNCE_COUNTER_MAX : positive
    );
    port (
        --! Clock signal
        clk   : in std_logic;
        --! Reset signal (active high, asynchronous)
        reset : in std_logic;
        
        --! Input signal to be debounced
        in_raw : in std_logic;
        --! Enable debouncing - can be used to synchronize the debouncing circuit to certain pulses.
        deb_en : in std_logic;

        --! Debounced output signal (1 while debounced btn is pressed / high)
        debounced : out std_logic;
        --! Active for one clock cycle when the debounced button is released
        released : out std_logic;
        --! Active for one clock cycle when the debounced button is pressed
        pressed : out std_logic
    );
end entity debouncer;

architecture rtl of debouncer is
    --! Fixed Debouncer Counter Value
    constant MOCK_DEBOUNCE_COUNTER_MAX : positive := 3;

    --! Debouncer Counter Bit Width
    constant COUNTER_WIDTH : positive := integer(ceil(log2(real(MOCK_DEBOUNCE_COUNTER_MAX))));

    --! Debouncer Counter
    signal counter_reg, counter_next : unsigned(COUNTER_WIDTH-1 downto 0) := (others => '0');
    signal output_reg, output_next : std_logic := '0';
begin

    --! Output Register Logic
    debounced <= output_reg;

    CLKREG : process(clk, reset) is
    begin
        if reset = '1' then
            counter_reg <= (others => '0');
            output_reg <= '0';
        elsif rising_edge(clk) then
            counter_reg <= counter_next;
            output_reg <= output_next;
        end if;
    end process CLKREG;

    --! Debouncer Counter Logic
    COUNTER : process(counter_reg, output_reg, in_raw, deb_en) is
    begin
        counter_next <= counter_reg;
        output_next <= output_reg;
        released <= '0';
        pressed <= '0';

        if in_raw = '1' then
            -- If input is high, increment counter
            if counter_reg = MOCK_DEBOUNCE_COUNTER_MAX then
                -- If counter reached top, set output register and set pressed-flag for one cycle
                if output_reg = '0' then
                    pressed <= '1';
                end if;
                output_next <= '1';
            else
                -- Increment counter if not at top
                if deb_en = '1' then
                    counter_next <= counter_reg + 1;
                end if;
            end if;
        else
            -- If input is low, decrement counter
            if counter_reg = 0 then
                -- If counter reached bottom, reset output register and set released-flag for one cycle
                if output_reg = '1' then
                    released <= '1';
                end if;
                output_next <= '0';
            else
                -- Decrement counter if not at bottom
                if deb_en = '1' then
                    counter_next <= counter_reg - 1;
                end if;
            end if;
        end if;
    end process COUNTER;

end architecture;