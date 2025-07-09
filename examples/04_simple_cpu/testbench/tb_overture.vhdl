-- Dependency: src/alu.vhdl, src/barrel_shifter.vhdl, src/condition.vhdl, src/execute.vhdl, src/decode.vhdl, src/fetch.vhdl, src/registers.vhdl, src/write_back.vhdl, src/overture.vhdl
-- TEROSHDL Documentation:
--! @title Testbench for Overture CPU
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 08.07.2025
--! @brief Testbench for the Overture CPU, testing various instructions and I/O operations
--!
--! This VHDL code implements a testbench for the Overture CPU, which is a simple CPU architecture.
--! It tests the functionality of the CPU, including instruction fetching, ALU operations, I/O operations,
--! and conditional jumps. The testbench includes multiple test cases, each designed to verify specific
--! aspects of the CPU's functionality. 
--!
--! Currently, the testbench includes four tests:
--! 1. Load Immediate and Copy: Loads a value into a register and copies it to an I/O address.
--! 2. ALU ADD: Performs an addition operation and outputs the result to an I/O address.
--! 3. Conditional Jump: Tests a conditional jump instruction based on the value in a register.
--! 4. Fibonacci Sequence: Outputs the first 8 values of the Fibonacci sequence to an I/O address.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_overture is
end entity tb_overture;

architecture behavior of tb_overture is

    -- Component Declaration for the Unit Under Test (UUT)
    component overture
        port (
            clk_i                  : in std_logic;
            reset_i                : in std_logic;
            memory_data_i          : in std_logic_vector(7 downto 0);
            memory_address_o       : out std_logic_vector(7 downto 0);
            io_address_o           : out std_logic_vector(7 downto 0);
            io_data_read_i         : in std_logic_vector(7 downto 0);
            io_data_write_o        : out std_logic_vector(7 downto 0);
            io_data_write_enable_o : out std_logic;
            cpu_halted_o           : out std_logic
        );
    end component;

    -- Inputs
    signal clk_i          : std_logic := '0';
    signal reset_i        : std_logic := '1';
    signal memory_data_i  : std_logic_vector(7 downto 0) := (others => '0');
    signal io_data_read_i : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Outputs
    signal memory_address_o       : std_logic_vector(7 downto 0);
    signal io_address_o           : std_logic_vector(7 downto 0);
    signal io_data_write_o        : std_logic_vector(7 downto 0);
    signal io_data_write_enable_o : std_logic;
    signal cpu_halted_o           : std_logic;
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    
    -- Memory array (256 bytes)
    type memory_array is array (0 to 255) of std_logic_vector(7 downto 0);
    signal memory : memory_array := (others => (others => '0'));
    
    -- I/O memory array (256 bytes)
    signal io_memory : memory_array := (others => (others => '0'));
    
    -- Test program definitions, similar to the memory array but flexible in size
    type test_program is array (natural range <>) of std_logic_vector(7 downto 0);
    
    -- Test 1: Load Immediate and Copy (Load 42 into R4)
    constant TEST1 : test_program := (
        x"2A",   -- LI 42 (0x2A)
        x"84",   -- COPY R0, R4
        x"00",   -- LI 0 (I/O address)
        x"86",   -- COPY R0, R6 (set I/O addr)
        x"A7",   -- COPY R4, IO (output)
        x"FF"    -- HALT (undefined instr)
    );
    
    -- Test 2: ALU ADD (10 + 20 = 30)
    constant TEST2 : test_program := (
        x"0A",   -- LI 10
        x"81",   -- COPY R0, R1
        x"14",   -- LI 20
        x"82",   -- COPY R0, R2
        x"44",   -- ADD (R3 = R1 + R2)
        x"00",   -- LI 0 (I/O addr)
        x"86",   -- COPY R0, R6
        x"9F",   -- COPY R3, IO (output)
        x"FF"    -- HALT
    );
    
    -- Test 3: Conditional Jump (Skip instruction if R3 != 0)
    constant TEST3 : test_program := (
        x"01",   -- LI 1
        x"83",   -- COPY R0, R3 (R3=1)
        x"05",   -- LI 5 (jump target)
        x"C5",   -- JMP if R3 != 0 (to addr 5)
        x"2A",   -- LI 42 (skipped)
        x"00",   -- LI 0 (I/O addr)
        x"86",   -- COPY R0, R6 (set I/O addr to 0 if test successful)
        x"9F",   -- COPY R3, IO (output R3=1 to I/O)
        x"FF"    -- HALT
    );
    
    -- Test 4: Fibonacci Sequence
    constant TEST4 : test_program := (
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
        x"FF"    -- HALT once 8 values are output
    );
    
    -- Expected Fibonacci sequence (first 8 values)
    type fib_sequence is array (0 to 7) of std_logic_vector(7 downto 0);
    constant FIB_EXPECTED : fib_sequence := (
        x"00", x"01", x"01", x"02", x"03", x"05", x"08", x"0D"
    );
    
    -- Test control
    signal test_num : integer := 1;
    signal fib_count : integer := 0;

	-- Testbench finished signal
	signal tb_finished : boolean := false;
    
begin

    -- Instantiate the Overture CPU
    DUT: overture port map (
        clk_i                  => clk_i,
        reset_i                => reset_i,
        memory_data_i          => memory_data_i,
        memory_address_o       => memory_address_o,
        io_address_o           => io_address_o,
        io_data_read_i         => io_data_read_i,
        io_data_write_o        => io_data_write_o,
        io_data_write_enable_o => io_data_write_enable_o,
        cpu_halted_o           => cpu_halted_o
    );
    
    -- Clock generation
	clk_i <= not clk_i after clk_period/2 when not tb_finished else '0';
    
    -- Memory read process
    mem_read: process(memory_address_o, memory)
        variable addr_int : integer;
    begin
        addr_int := to_integer(unsigned(memory_address_o));
        memory_data_i <= memory(addr_int);
    end process;
    
    -- I/O process
    io_process: process(clk_i, io_address_o, io_memory)
        variable addr_int : integer;
    begin
        -- I/O read
		addr_int := to_integer(unsigned(io_address_o));
        io_data_read_i <= io_memory(addr_int);
        
		if rising_edge(clk_i) then  
            -- I/O write
            if io_data_write_enable_o = '1' then
				-- Report the address and data written
				report "Address: " & integer'image(addr_int) & 
						", Data Written: " & to_string(io_data_write_o);

                io_memory(addr_int) <= io_data_write_o;
                
                -- Test-specific checks
                case test_num is
                    when 1 => 
                        if addr_int = 0 and io_data_write_o = x"2A" then
                            report "Test 1 Passed: Output 42" severity note;
                        else
                            report "Test 1 Failed" severity error;
                        end if;
                        
                    when 2 => 
                        if addr_int = 0 and io_data_write_o = x"1E" then
                            report "Test 2 Passed: Output 30" severity note;
                        else
                            report "Test 2 Failed" severity error;
                        end if;
                        
                    when 3 => 
                        if addr_int = 0 and io_data_write_o = x"01" then
                            report "Test 3 Passed: Output 1" severity note;
                        else
                            report "Test 3 Failed" severity error;
                        end if;
                        
                    when 4 => 
                        if fib_count < 8 then
                            if io_data_write_o = FIB_EXPECTED(fib_count) then
                                report "Test 4: Fibonacci value " & integer'image(fib_count) & 
                                       " = " & integer'image(to_integer(unsigned(io_data_write_o))) 
                                       severity note;
                            else
                                report "Test 4 Mismatch at index " & integer'image(fib_count) & 
                                       ": Expected " & integer'image(to_integer(unsigned(FIB_EXPECTED(fib_count)))) & 
                                       ", Got " & integer'image(to_integer(unsigned(io_data_write_o))) 
                                       severity error;
                            end if;
                            fib_count <= fib_count + 1;
                        end if;
                        
                    when others => null;
                end case;
            end if;
        end if;
    end process;
    
    -- Stimulus process
    stim_proc: process
        procedure load_program(prog : test_program) is
        begin
            for i in 0 to 255 loop
                if i < prog'length then
                    memory(i) <= prog(i);
                else
                    memory(i) <= x"FF";  -- HALT
                end if;
            end loop;
        end procedure;
    begin
        -- Initialize inputs
        reset_i <= '1';
        wait for clk_period * 2;
		wait until rising_edge(clk_i);
        
        -- Test 1: Load Immediate and Copy
        report "Starting Test 1: Load Immediate and Copy";
        test_num <= 1;
        load_program(TEST1);
        reset_i <= '0';
        wait on clk_i until rising_edge(clk_i) and cpu_halted_o = '1';
        wait for clk_period * 2;
        
        -- Test 2: ALU ADD
        report "Starting Test 2: ALU ADD";
        test_num <= 2;
        reset_i <= '1';
        wait for clk_period * 2;
        load_program(TEST2);
        reset_i <= '0';
        wait on clk_i until rising_edge(clk_i) and cpu_halted_o = '1';
        wait for clk_period * 2;
        
        -- Test 3: Conditional Jump
        report "Starting Test 3: Conditional Jump";
        test_num <= 3;
        reset_i <= '1';
        wait for clk_period * 2;
        load_program(TEST3);
        reset_i <= '0';
        wait on clk_i until rising_edge(clk_i) and cpu_halted_o = '1';
        wait for clk_period * 2;
        
        -- Test 4: Fibonacci Sequence
        report "Starting Test 4: Fibonacci Sequence";
        test_num <= 4;
        reset_i <= '1';
        wait for clk_period * 2;
        load_program(TEST4);
        reset_i <= '0';
        wait on clk_i until rising_edge(clk_i) and cpu_halted_o = '1';
        wait for clk_period * 2;
        
        -- Check the fibonacci sequence (8 values in io_memory)
        for i in 0 to 7 loop
            if io_memory(i) = FIB_EXPECTED(i) then
                report "Fibonacci check " & integer'image(i) & " passed" severity note;
            else
                report "Fibonacci check " & integer'image(i) & " failed" severity error;
            end if;
        end loop;
        
        report "All tests completed" severity note;
		tb_finished <= true;
        wait;
    end process;
	
end architecture;