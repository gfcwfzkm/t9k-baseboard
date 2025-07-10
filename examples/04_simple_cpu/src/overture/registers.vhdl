-- TEROSHDL Documentation
--! @title Register File
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Register file for a simple CPU
--!
--! This VHDL code implements a register file for a simple CPU.
--! It contains 7 registers, each 8 bits wide. The register file supports reading and writing to registers.
--! The following operations are supported:
--! - Writing data to a register
--! - Reading data from a register
--! - Resetting all registers to 0
--!
--! The register file also provides direct outputs for the special registers for jump address, I/O address, and ALU operand A.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
    port (
        --! Clock signal for synchronous operations    
        clk_i           : in std_logic;
        --! Active-high, synchronous reset signal to reset all registers
        reset_i         : in std_logic;
        
        --! Register address for write operations
        write_address_i : in std_logic_vector(2 downto 0);
        --! Data to write to the specified register
        write_data_i    : in std_logic_vector(7 downto 0);
        --! Write enable signal to control write operations
        write_enable_i  : in std_logic;

        --! Register address for read operations (asynchronous read)
        read_address_i  : in std_logic_vector(2 downto 0);
        --! Data read from the specified register
        read_data_o     : out std_logic_vector(7 downto 0);

        --! Direct output for the jump address register (register 0)
        jump_address_o  : out std_logic_vector(7 downto 0);
        --! Direct output for the ALU operand A register (register 1)
        alu_operand_a_o : out std_logic_vector(7 downto 0);
        --! Direct output for the I/O address register (register 6)
        io_address_o    : out std_logic_vector(7 downto 0)
    );
end entity registers;

architecture rtl of registers is

    --! Register file type definition
    type t_registers is array (0 to 6) of std_logic_vector(7 downto 0);
    --! Register file signal declaration
    signal register_file : t_registers;

begin

    -- Read data from the specified register
    read_data_o <= x"00" when read_address_i = "111" else register_file(to_integer(unsigned(read_address_i)));
    
    -- Direct outputs for special registers
    jump_address_o  <= register_file(0); -- Register 0 holds the jump address
    alu_operand_a_o <= register_file(1); -- Register 1 holds the ALU operand A
    io_address_o    <= register_file(6); -- Register 6 holds the I/O address

    --! Clock process for register file
    CLKREG : process (clk_i, reset_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                register_file <= (others => (others => '0')); -- Reset all registers to 0
            else
                register_file <= register_file; -- Keep current state
                
                if write_enable_i = '1' and unsigned(write_address_i) < register_file'length then
                    -- Write data to the specified register
                    register_file(to_integer(unsigned(write_address_i))) <= write_data_i;
                end if;
            end if;
        end if;
    end process CLKREG;

end architecture;