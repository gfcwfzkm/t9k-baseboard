-- TEROSHDL Documentation:
--! @title ROM Module
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 10.07.2025
--! @brief A simple ROM module with asynchronous read.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity rom is
    generic (
        --! Size of the ROM in words
        ROM_SIZE    : integer := 256;
        --! Width of each word in bits
        WORD_WIDTH  : integer := 8
    );
    port (
        --! Address to read from the ROM
        address_i   : in std_logic_vector(integer(ceil(log2(real(ROM_SIZE))))-1 downto 0);
        --! Output data read from the ROM, async read
        data_out_o  : out std_logic_vector(WORD_WIDTH-1 downto 0)		
    );
end entity rom;

architecture rtl of rom is

    --! Type definition for the ROM data structure
    type t_rom is array (0 to ROM_SIZE-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
    --! Signal to hold the ROM data
    signal rom_data : t_rom := (
        -- Initialize with some example data
        x"00",
        others => (others => '1') -- Fill the rest with ones
    );

begin

    --! Async read the ROM data
    data_out_o <= rom_data(to_integer(unsigned(address_i)));

end architecture;