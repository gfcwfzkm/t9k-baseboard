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
        x"00",  -- 0000: LDI #00
        x"86",  -- 0001: MOV R6 R0
        x"84",  -- 0002: MOV R4 R0
        x"01",  -- 0003: LDI 0b1
        x"85",  -- 0004: MOV R5 R0
        x"A7",  -- 0005: MOV IO R4
        x"B1",  -- 0006: MOV R1 R6
        x"10",  -- 0007: LDI IO_GPIO
        x"86",  -- 0008: MOV R6 R0
        x"A7",  -- 0009: OUT R4
        x"8E",  -- 000A: MOV R6 R1
        x"A1",  -- 000B: MOV R1 R4
        x"AA",  -- 000C: MOV R2 R5
        x"44",  -- 000D: OP ADD
        x"AC",  -- 000E: MOV R4 R5
        x"9D",  -- 000F: MOV R5 R3
        x"00",  -- 0010: LDI 0
        x"81",  -- 0011: MOV R1 R0
        x"01",  -- 0012: LDI 1
        x"82",  -- 0013: MOV R2 R0
        x"45",  -- 0014: OP SUB
        x"B1",  -- 0015: MOV R1 R6
        x"12",  -- 0016: LDI IO_DELAY_MS
        x"86",  -- 0017: MOV R6 R0
        x"9F",  -- 0018: MOV IO R3
        x"BB",  -- 0019: MOV R3 IO
        x"19",  -- 001A: LDI delay_ms
        x"C5",  -- 001B: JNZ
        x"8E",  -- 001C: MOV R6 R1
        x"01",  -- 001D: LDI 1
        x"81",  -- 001E: MOV R1 R0
        x"B2",  -- 001F: MOV R2 R6
        x"44",  -- 0020: OP ADD
        x"9E",  -- 0021: MOV R6 R3
        x"07",  -- 0022: LDI TOP_ADDR
        x"81",  -- 0023: MOV R1 R0
        x"45",  -- 0024: OP SUB
        x"05",  -- 0025: LDI loop
        x"C5",  -- 0026: JNZ
        x"FF",  -- 0027: HLT
        others => (others => '1') -- Fill the rest with ones
    );

begin

    --! Async read the ROM data
    data_out_o <= rom_data(to_integer(unsigned(address_i)));

end architecture;