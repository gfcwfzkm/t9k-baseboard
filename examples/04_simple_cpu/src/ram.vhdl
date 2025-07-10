-- TEROSHDL Documentation:
--! @title Simple RAM Module
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 10.07.2025
--! @brief A simple synchronous RAM module with reset and write enable.
--!


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity ram is
    generic (
        --! Size of the RAM in words
        RAM_SIZE : integer := 256;
        --! Width of each word in bits
        WORD_WIDTH : integer := 8
    );
    port (
        --! Clock signal for synchronous operations
        clk_i           : in std_logic;
        --! Synchronous, active-high reset signal
        reset_i         : in std_logic;
        
        --! Address for the RAM access, calculated based on RAM_SIZE
        address_i    	: in std_logic_vector(integer(ceil(log2(real(RAM_SIZE))))-1 downto 0);
        --! Write enable signal, when high allows writing to the RAM
        write_enable_i  : in std_logic;
        --! Input data to be written to the RAM
        data_in_i       : in std_logic_vector(WORD_WIDTH-1 downto 0);
        --! Output data read from the RAM, async read
        data_out_o      : out std_logic_vector(WORD_WIDTH-1 downto 0)
    );
end entity ram;

architecture rtl of ram is

    --! Type definition for the RAM data structure
    type t_ram is array (0 to RAM_SIZE-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
    --! Signal to hold the RAM data
    signal ram_data : t_ram;

begin

    --! Async read the RAM data
    data_out_o <= ram_data(to_integer(unsigned(address_i)));

    --! Basic RAM process
    process (clk_i, reset_i)
    begin
        if rising_edge(clk_i) then
            ram_data <= ram_data;  -- Maintain the current state of RAM data
            if reset_i = '1' then
                -- Reset the RAM contents to zero
                ram_data <= (others => (others => '0'));
            else
                if write_enable_i = '1' then
                    -- Write data to the specified address
                    ram_data(to_integer(unsigned(address_i))) <= data_in_i;
                end if;
            end if;
        end if;
    end process;

end architecture;
