-- TEROSHDL Documentation:
--! @title TMDS Encoder Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 15.06.2025
--! @brief Tests the TMDS encoder entity
--!
--! This testbench simulates the TMDS encoder entity, providing various input patterns
--! and checking the output against expected values. It includes edge cases and normal operation
--! cases, and reports any mismatches. The testbench uses a CSV file to provide input stimuli
--! and expected output values, allowing for easy modification of test cases.
--! 
--! The CSV file stimuli is based on a simulation waveform from the MIT course 6.205,
--! which has been converted to a VDC file and its values extracted into a Python script.
--! Source of the waveform: https://fpga.mit.edu/6205/F24/assignments/hdmi/tmds_ds

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.helper_pkg.all;

entity tb_tmds_encoder is
end entity tb_tmds_encoder;

architecture behavioral of tb_tmds_encoder is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;	--! Clock period for simulation

    -- Signals going to DUT
    signal clk          : std_logic := '0';	--! Clock signal
    signal reset        : std_logic := '1';	--! Reset signal, active high
    signal disp_enable  : std_logic := '0';	--! Display enable signal, active high
    signal hsync        : std_logic := '0';	--! Horizontal sync signal, active high
    signal vsync        : std_logic := '0';	--! Vertical sync signal, active high
    --! Color data input signal, 8 bits wide
    signal color_data   : std_logic_vector(7 downto 0) := (others => '0');
    --! Signals coming from DUT, the encoded TMDS output
    signal tmds_encoded : std_logic_vector(9 downto 0);
    
    -- Testbench control
    signal test_running : boolean := true;	--! Control signal to end simulation
begin
    --! Instantiate DUT
    dut: entity work.tmds_encoder(rtl)
        port map (
            clk          => clk,
            reset        => reset,
            disp_enable  => disp_enable,
            hsync        => hsync,
            vsync        => vsync,
            color_data   => color_data,
            tmds_encoded => tmds_encoded
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2 when test_running else '0';

    --! Test process
    test_proc: process
        -- Variables needed to parse the CSV file
        file csv_file     : text;

        -- Stimuli generated from the simulation waveform found at the 
        -- MIT course 6.205 The .FST simulation has been converted to .VDC, with
        -- its values extracted into a python file. Source of the waveform:
        -- https://fpga.mit.edu/6205/F24/assignments/hdmi/tmds_ds
        constant csv_path : string := "stimuli.csv";
        variable csv_line : line;
        variable cycle_num: integer;
        variable data_in  : integer;
        variable ve_in    : integer;
        variable ctrl_in  : integer;
        variable q_m      : integer;
        variable exp_out  : integer;
        variable comma    : character;
        
        -- Edge case definitions
        type test_vector is record
            data_in  : std_logic_vector(7 downto 0);
            disp_en  : std_logic;
            vsync    : std_logic;
            hsync    : std_logic;
            expected : std_logic_vector(9 downto 0);
        end record;
        type edge_case_array is array (natural range <>) of test_vector;
        
        -- Define edge cases (14 cases)
        constant EDGE_CASES : edge_case_array(0 to 13) := (
            -- Control tokens (disp_en=0)
            (x"00", '0', '0', '0', std_logic_vector(to_unsigned(852, 10))),  -- Ctrl 0
            (x"00", '0', '0', '1', std_logic_vector(to_unsigned(171, 10))),  -- Ctrl 1
            (x"00", '0', '1', '0', std_logic_vector(to_unsigned(340, 10))),  -- Ctrl 2
            (x"00", '0', '1', '1', std_logic_vector(to_unsigned(683, 10))),  -- Ctrl 3
            
            -- Data patterns (disp_en=1)
            (x"00", '1', '0', '0', "0100000000"), -- All zeros
            (x"FF", '1', '0', '0', "0011111111"),  -- All ones
            (x"55", '1', '0', '0', "0100110011"),  -- 01010101
            (x"AA", '1', '0', '0', "1000110011"),  -- 10101010
            (x"0F", '1', '0', '0', "1111111010"),  -- 00001111
            (x"F0", '1', '0', '0', "1000000101"),  -- 11110000
            (x"81", '1', '0', '0', "0101111111"),  -- 10000001
            (x"7E", '1', '0', '0', "0010000000"),  -- 01111110
            (x"FE", '1', '0', '0', "1011111111"),  -- 11111110
            (x"01", '1', '0', '0', "1100000000")   -- 00000001
        );
        
        -- Counters for error reporting
        variable errors      : natural := 0;
        variable total_tests : natural := 0;
        variable dc_level    : integer := 0;

        -- Result we're expecting
        variable exp_vector  : std_logic_vector(9 downto 0);
    begin
        -- Reset sequence
        reset <= '1';
        wait for CLK_PERIOD * 2;
        wait until rising_edge(clk);
        reset <= '0';

        -- Test edge cases
        report "Testing edge cases...";
        for i in EDGE_CASES'range loop
            wait until falling_edge(clk);
            wait for 1 ns;
            -- Apply inputs
            color_data  <= EDGE_CASES(i).data_in;
            disp_enable <= EDGE_CASES(i).disp_en;
            vsync       <= EDGE_CASES(i).vsync;
            hsync       <= EDGE_CASES(i).hsync;
            total_tests := total_tests + 1;
            
            -- Wait for the rising edge, which is when the output is updated
            wait until rising_edge(clk);
            wait for 1 ns;
            
            -- Check output
            exp_vector := EDGE_CASES(i).expected;
            if tmds_encoded /= exp_vector then
                report "Edge case " & integer'image(i) & " failed!" & lf &
                       "Input:  data=" & to_hstring(EDGE_CASES(i).data_in) & 
                       ", DE=" & std_logic'image(EDGE_CASES(i).disp_en) &
                       ", VS=" & std_logic'image(EDGE_CASES(i).vsync) &
                       ", HS=" & std_logic'image(EDGE_CASES(i).hsync) & lf &
                       "Output: " & to_string(tmds_encoded) & " (expected: " & to_string(exp_vector) & ")"
                    severity error;
                errors := errors + 1;
            end if;
            
            -- Calculate the DC balance to ensure the "DS" part of TMDS is working
            dc_level := dc_level + count_ones(tmds_encoded) - (10 - count_ones(tmds_encoded));
            wait for 1 ns;
        end loop;

        -- Final report
        report "EDGE CASE TEST COMPLETE: " & integer'image(total_tests - errors) & "/" & 
               integer'image(total_tests) & " tests passed";
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report integer'image(errors) & " TESTS FAILED" severity error;
        end if;

        -- Report DC balance level
        if dc_level > 8 or dc_level < -8 then
            report "DC balance level out of range: " & integer'image(dc_level) severity error;
        else
            report "DC balance level within acceptable range: " & integer'image(dc_level) severity note;
        end if;
        
        errors := 0;  -- Reset error count for next phase
        total_tests := 0;
        dc_level := 0;  -- Reset DC balance level for next phase

        -- Reset for next phase
        wait until falling_edge(clk);
        wait for 1 ns;
        reset <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        reset <= '0';

        -- Test CSV vectors
        report "Testing CSV vectors...";
        file_open(csv_file, "stimuli.csv", read_mode);
        readline(csv_file, csv_line);  -- Skip header
        
        while not endfile(csv_file) loop
            -- Read in the CSV line...
            readline(csv_file, csv_line);
            -- ... and parse the values. Not great, not terrible to read it in.
            read(csv_line, cycle_num);
            read(csv_line, comma);
            read(csv_line, data_in);
            read(csv_line, comma);
            read(csv_line, ve_in);
            read(csv_line, comma);
            read(csv_line, ctrl_in);
            read(csv_line, comma);
            read(csv_line, q_m);
            read(csv_line, comma);
            read(csv_line, exp_out);

            wait until falling_edge(clk);
            wait for 1 ns;
            
            -- Apply inputs
            color_data  <= std_logic_vector(to_unsigned(data_in, 8));
            disp_enable <= '1' when ve_in = 1 else '0';
            vsync       <= '1' when ctrl_in >= 2 else '0';  -- ctrl_in[1]
            hsync       <= '1' when ctrl_in mod 2 = 1 else '0';  -- ctrl_in[0]
            total_tests := total_tests + 1;
            
            -- Wait for output to stabilize
            wait until rising_edge(clk);
            wait for 1 ns;
            
            -- Check output
            exp_vector := std_logic_vector(to_unsigned(exp_out, 10));
            if tmds_encoded /= exp_vector then
                report "CSV vector @ cycle " & integer'image(cycle_num) & " failed!" & lf &
                       "Input:  data=" & to_hstring(color_data) & 
                       ", DE=" & std_logic'image(disp_enable) &
                       ", VS=" & std_logic'image(vsync) &
                       ", HS=" & std_logic'image(hsync) & lf &
                       "Output: " & to_string(tmds_encoded) & " (expected: " & to_string(exp_vector) & ")"
                    severity error;
                errors := errors + 1;
            end if;

            -- Calculate the DC balance to ensure the "DS" part of TMDS is working
            -- Add the amount of ones and subtract the amount of zeros. The goal is, that
            -- the DC balance stays around zero (+/- 8) after all tests.
            dc_level := dc_level + count_ones(tmds_encoded) - (10 - count_ones(tmds_encoded));
        end loop;
        file_close(csv_file);

        -- Final report
        test_running <= false;
        report "CSV TEST COMPLETE: " & integer'image(total_tests - errors) & "/" & 
               integer'image(total_tests) & " tests passed";
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report integer'image(errors) & " TESTS FAILED" severity error;
        end if;

        -- Report DC balance level
        if dc_level > 8 or dc_level < -8 then
            report "DC balance level out of range: " & integer'image(dc_level) severity error;
        else
            report "DC balance level within acceptable range: " & integer'image(dc_level) severity note;
        end if;
        wait;
    end process test_proc;
end architecture behavioral;