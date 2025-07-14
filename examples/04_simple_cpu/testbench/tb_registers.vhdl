-- Dependency: src/overture/registers.vhdl
-- TEROSHDL Documentation:
--! @title Testbench for Register File
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 08.07.2025
--! @brief Testbench for the register file of a simple CPU
--!
--! This VHDL code implements a testbench for the register file of a simple CPU.
--! It tests the functionality of the register file, including reading and writing to registers,
--! resetting registers, and verifying special outputs for jump address, ALU operand A, and I/O address.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_registers is
end entity tb_registers;

architecture tb of tb_registers is

    --! Clock period for the testbench
    constant CLK_PERIOD : time := 10 ns;
    
    --! Signals for the testbench
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal write_address : std_logic_vector(2 downto 0) := (others => '0');
    signal write_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal write_enable  : std_logic := '0';
    signal read_address  : std_logic_vector(2 downto 0) := (others => '0');
    signal read_data     : std_logic_vector(7 downto 0);
    signal jump_address  : std_logic_vector(7 downto 0);
    signal alu_operand_a : std_logic_vector(7 downto 0);
    signal io_address    : std_logic_vector(7 downto 0);
    
    --! Signals for test control
    signal tb_finished   : boolean := false;
    --! Signal to indicate if the test passed
    signal test_passed   : boolean := true;

begin

    --! Instantiate Unit Under Test
    DUT: entity work.registers
        port map (
            clk_i            => clk,
            reset_i          => reset,
            write_address_i  => write_address,
            write_data_i     => write_data,
            write_enable_i   => write_enable,
            read_address_i   => read_address,
            read_data_o      => read_data,
            jump_address_o   => jump_address,
            alu_operand_a_o  => alu_operand_a,
            io_address_o     => io_address
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD/2 when not tb_finished else '0';

    --! Main test process
    test_process: process
        --! Perform Reset on the DUT
        procedure sync_reset is
        begin
            reset <= '1';
            wait until rising_edge(clk);
            reset <= '0';
            wait until rising_edge(clk);
        end procedure;
        
        --! Write Data Byte to a Register
        procedure write_register(
            addr : in std_logic_vector(2 downto 0);
            data : in std_logic_vector(7 downto 0)) is
        begin
            write_address <= addr;
            write_data <= data;
            write_enable <= '1';
            wait until rising_edge(clk);
            write_enable <= '0';
        end procedure;
        
        --! Verify the contents of a Register
        procedure verify_register(
            addr      : in std_logic_vector(2 downto 0);
            expected  : in std_logic_vector(7 downto 0);
            test_name : in string) is
            variable index : natural;
        begin
            -- Address we've written to
            index := to_integer(unsigned(addr));
            -- Set the read-address to the register we want to verify
            read_address <= addr;
            wait for 1 ns;
            
            -- Read the data from the register and check it
            if read_data /= expected then
                report test_name & ": Register " & integer'image(index) & 
                       " read error. Expected: " & to_hstring(expected) & 
                       " Got: " & to_hstring(read_data)
                severity error;
                test_passed <= false;
            end if;
            
            -- Verify special outputs if we've written to them
            if index = 0 and jump_address /= expected then
                report test_name & ": Jump address error. Expected: " & 
                       to_hstring(expected) & " Got: " & to_hstring(jump_address)
                severity error;
                test_passed <= false;
            end if;
            
            if index = 1 and alu_operand_a /= expected then
                report test_name & ": ALU operand A error. Expected: " & 
                       to_hstring(expected) & " Got: " & to_hstring(alu_operand_a)
                severity error;
                test_passed <= false;
            end if;
            
            if index = 6 and io_address /= expected then
                report test_name & ": I/O address error. Expected: " & 
                       to_hstring(expected) & " Got: " & to_hstring(io_address)
                severity error;
                test_passed <= false;
            end if;
        end procedure;
        
        --! Verify illegal read from an unimplemented register
        -- This should always return 00 for any address > 6
        -- as the register file only has 7 registers (0-6)
        procedure verify_illegal_read(
            addr      : in std_logic_vector(2 downto 0);
            test_name : in string)
        is
        begin
            read_address <= addr;
            wait for 1 ns;
            
            if read_data /= x"00" then
                report test_name & ": Illegal read error. Expected: 00" & 
                       " Got: " & to_hstring(read_data)
                severity error;
                test_passed <= false;
            end if;
        end procedure;
    begin
        -- Initialize
        wait for CLK_PERIOD;

        report "Starting Register File Testbench..." severity note;
        
        -- Reset functionality, ensure all registers are set to zero
        sync_reset;
        for i in 0 to 6 loop
            verify_register(
                std_logic_vector(to_unsigned(i, 3)),
                x"00",
                "Reset Test"
            );
        end loop;
        
        -- Write/Read all valid registers
        for i in 0 to 6 loop
            write_register(
                std_logic_vector(to_unsigned(i, 3)),
                std_logic_vector(to_unsigned(16#10# + i, 8))
            );
            verify_register(
                std_logic_vector(to_unsigned(i, 3)),
                std_logic_vector(to_unsigned(16#10# + i, 8)),
                "Write/Read Test"
            );
        end loop;
        
        -- Verify register independence
        for i in 0 to 6 loop
            verify_register(
                std_logic_vector(to_unsigned(i, 3)),
                std_logic_vector(to_unsigned(16#10# + i, 8)),
                "Independence Test"
            );
        end loop;
        
        -- Illegal write (address 7), nothing should change on the 
        -- other registers as this write should be ignored
        write_register("111", x"FF");
        for i in 0 to 6 loop
            verify_register(
                std_logic_vector(to_unsigned(i, 3)),
                std_logic_vector(to_unsigned(16#10# + i, 8)),
                "Illegal Write Test"
            );
        end loop;
        
        -- Illegal read (address 7), should return zero
        verify_illegal_read("111", "Illegal Read Test");
        
        -- Write enable disabled - try to write to a register
        -- while the write_enable signal is low
        write_register("001", x"AA");  -- Valid write to pre-set register
        verify_register("001", x"AA", "Write Enable Test");
        
        write_address <= "001";
        write_data    <= x"BB";
        write_enable  <= '0';
        wait until rising_edge(clk);
        verify_register("001", x"AA", "Write Disabled Test");
        
        -- Final report
        if test_passed then
            report "All tests passed successfully!" severity note;
        else
            report "Some tests failed!" severity error;
        end if;

        tb_finished <= true;
        wait;
    end process test_process;

end architecture tb;