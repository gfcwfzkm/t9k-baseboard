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
        -- Initialize registers
        x"00",   -- LI 0
        x"84",   -- COPY R0, R4 (current=0)
        x"01",   -- LI 1
        x"85",   -- COPY R0, R5 (next=1)
        x"00",   -- LI 0
        x"86",   -- COPY R0, R6 (I/O addr=0)
        x"C0",   -- JMP NEVER (basically a NOP)
        
        -- Loop start (output current)
        x"A7",   -- COPY R4, IO (output)
        x"A1",   -- COPY R4, R1 (for ALU)
        x"AA",   -- COPY R5, R2 (for ALU)
        x"44",   -- ADD (R3 = R1 + R2)
        x"AC",   -- COPY R5, R4 (current = next)
        x"9D",   -- COPY R3, R5 (next = sum)
		x"01",   -- LI 1
		x"81",   -- COPY R0, R1
		x"B2",   -- COPY R6, R2
		x"44",   -- ADD (R3 = R1 + R2)
		x"9E",   -- COPY R3, R6 (increment I/O address)
		x"07",   -- LI 7 (jump to loop start and to check if we got 8 values)
		x"81",   -- COPY R0, R1 (R1 = 7)
		--x"9A",   -- COPY R3, R2 (R2 = IOADDR)
		x"45",   -- SUB (R3 = R1 - R2)
        x"C5",   -- JMP if R3 != 0 (to loop start if we have less than 8 values)
        x"FF",    -- HALT once 8 values are output
        others => (others => '1') -- Fill the rest with ones
    );

begin

    --! Async read the ROM data
    data_out_o <= rom_data(to_integer(unsigned(address_i)));

end architecture;