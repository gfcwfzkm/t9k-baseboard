-- Dependency: src/decode.vhdl
-- TEROSHDL Documentation:
--! @title Decode Unit Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 07.07.2025
--! @brief Testbench for the Decode Unit of a simple CPU
--!
--! This VHDL code implements a testbench for the decode unit of a simple CPU.
--! It includes fixed test cases and random test cases to verify the functionality of the decode unit.
--! The testbench checks the decoded control signals against expected values and reports any mismatches.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_decode is
end tb_decode;

architecture sim of tb_decode is
    signal fetched_instruction : std_logic_vector(7 downto 0);
    signal instruction_type    : std_logic_vector(1 downto 0);
    signal alu_op              : std_logic_vector(2 downto 0);
    signal jump_condition      : std_logic_vector(2 downto 0);
    signal src_reg             : std_logic_vector(2 downto 0);
    signal dst_reg             : std_logic_vector(2 downto 0);
    signal immediate_value     : std_logic_vector(5 downto 0);
    signal halt                : std_logic;

    type test_vector is record
        inst     : std_logic_vector(7 downto 0);
        type_exp : std_logic_vector(1 downto 0);
        alu_exp  : std_logic_vector(2 downto 0);
        jump_exp : std_logic_vector(2 downto 0);
        src_exp  : std_logic_vector(2 downto 0);
        dst_exp  : std_logic_vector(2 downto 0);
        imm_exp  : std_logic_vector(5 downto 0);
        halt_exp : std_logic;
    end record;

    type fixed_vector_array is array (natural range <>) of test_vector;
    constant fixed_vectors : fixed_vector_array := (
        -- Load Immediate: 0x2A -> "00101010"
        (x"2A", "00", "000", "000", "000", "000", "101010", '0'),
        -- ALU Valid: 0x45 -> "01000101"
        (x"45", "01", "101", "000", "010", "011", "000000", '0'),
        -- ALU Invalid: 0x40 -> "01100000"
        (x"60", "01", "000", "000", "000", "000", "000000", '1'),
        -- Copy: 0xAC -> "10101100"
        (x"AC", "10", "000", "000", "101", "100", "000000", '0'),
        -- Jump Valid: 0xC2 -> "11000010"
        (x"C2", "11", "000", "010", "011", "000", "000000", '0'),
        -- Jump Invalid: 0xCA -> "11001010"
        (x"CA", "11", "000", "000", "000", "000", "000000", '1'),
        -- Load Immediate: 0x3F -> "00111111"
        (x"3F", "00", "000", "000", "000", "000", "111111", '0')
    );

    function compute_expected(inst : std_logic_vector(7 downto 0)) return test_vector is
        variable v_type : std_logic_vector(1 downto 0);
        variable v_alu_op, v_jump, v_src, v_dst : std_logic_vector(2 downto 0);
        variable v_imm : std_logic_vector(5 downto 0);
        variable v_halt : std_logic;
    begin
        v_type := inst(7 downto 6);
        v_alu_op := "000";
        v_jump := "000";
        v_src := "000";
        v_dst := "000";
        v_imm := "000000";
        v_halt := '0';

        case v_type is
            when "00" => 
                v_dst := "000";
                v_imm := inst(5 downto 0);
            when "01" =>
                if inst(5 downto 3) /= "000" then
                    v_halt := '1';
                else
                    v_src := "010";
                    v_dst := "011";
                    v_alu_op := inst(2 downto 0);
                end if;
            when "10" =>
                v_src := inst(5 downto 3);
                v_dst := inst(2 downto 0);
            when "11" =>
                if inst(5 downto 3) /= "000" then
                    v_halt := '1';
                else
                    v_src := "011";
                    v_jump := inst(2 downto 0);
                end if;
            when others =>
                v_halt := '1';
        end case;

        return (inst, v_type, v_alu_op, v_jump, v_src, v_dst, v_imm, v_halt);
    end function;
begin
    uut: entity work.decode
        port map (
            fetched_instruction => fetched_instruction,
            instruction_type => instruction_type,
            alu_op => alu_op,
            jump_condition => jump_condition,
            src_reg => src_reg,
            dst_reg => dst_reg,
            immediate_value => immediate_value,
            halt => halt
        );

    test_runner: process
        variable errors : integer := 0;
        variable expected : test_vector;
        variable seed1, seed2 : positive := 1;
        variable rand : real;
        variable rand_num : integer;
    begin
        -- Fixed test cases
        report "Starting fixed test cases...";
        for i in fixed_vectors'range loop
            fetched_instruction <= fixed_vectors(i).inst;
            wait for 10 ns;

            if instruction_type /= fixed_vectors(i).type_exp then
                report "Fixed test " & integer'image(i) & ": type mismatch. Expected " & 
                       to_string(fixed_vectors(i).type_exp) & ", got " & to_string(instruction_type) 
                       severity error;
                errors := errors + 1;
            end if;
            if alu_op /= fixed_vectors(i).alu_exp then
                report "Fixed test " & integer'image(i) & ": alu_op mismatch. Expected " & 
                       to_string(fixed_vectors(i).alu_exp) & ", got " & to_string(alu_op) 
                       severity error;
                errors := errors + 1;
            end if;
            if jump_condition /= fixed_vectors(i).jump_exp then
                report "Fixed test " & integer'image(i) & ": jump_condition mismatch. Expected " & 
                       to_string(fixed_vectors(i).jump_exp) & ", got " & to_string(jump_condition) 
                       severity error;
                errors := errors + 1;
            end if;
            if src_reg /= fixed_vectors(i).src_exp then
                report "Fixed test " & integer'image(i) & ": src_reg mismatch. Expected " & 
                       to_string(fixed_vectors(i).src_exp) & ", got " & to_string(src_reg) 
                       severity error;
                errors := errors + 1;
            end if;
            if dst_reg /= fixed_vectors(i).dst_exp then
                report "Fixed test " & integer'image(i) & ": dst_reg mismatch. Expected " & 
                       to_string(fixed_vectors(i).dst_exp) & ", got " & to_string(dst_reg) 
                       severity error;
                errors := errors + 1;
            end if;
            if immediate_value /= fixed_vectors(i).imm_exp then
                report "Fixed test " & integer'image(i) & ": immediate_value mismatch. Expected " & 
                       to_string(fixed_vectors(i).imm_exp) & ", got " & to_string(immediate_value) 
                       severity error;
                errors := errors + 1;
            end if;
            if halt /= fixed_vectors(i).halt_exp then
                report "Fixed test " & integer'image(i) & ": halt mismatch. Expected " & 
                       to_string(fixed_vectors(i).halt_exp) & ", got " & to_string(halt) 
                       severity error;
                errors := errors + 1;
            end if;
        end loop;

		if errors > 0 then
			report "Fixed tests completed with " & integer'image(errors) & " errors." severity failure;
		else
			report "Fixed tests passed successfully." severity note;
		end if;

        -- Random test cases
        report "Starting random test cases...";
        for i in 1 to 100 loop
            uniform(seed1, seed2, rand);
            rand_num := integer(floor(rand * 256.0));
            fetched_instruction <= std_logic_vector(to_unsigned(rand_num, 8));
			wait for 1 ns;
            expected := compute_expected(fetched_instruction);
            wait for 4 ns;

            if instruction_type /= expected.type_exp then
                report "Random test " & integer'image(i) & ": type mismatch. Expected " & 
                       to_string(expected.type_exp) & ", got " & to_string(instruction_type) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            if alu_op /= expected.alu_exp then
                report "Random test " & integer'image(i) & ": alu_op mismatch. Expected " & 
                       to_string(expected.alu_exp) & ", got " & to_string(alu_op) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            if jump_condition /= expected.jump_exp then
                report "Random test " & integer'image(i) & ": jump_condition mismatch. Expected " & 
                       to_string(expected.jump_exp) & ", got " & to_string(jump_condition) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            if src_reg /= expected.src_exp then
                report "Random test " & integer'image(i) & ": src_reg mismatch. Expected " & 
                       to_string(expected.src_exp) & ", got " & to_string(src_reg) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            if dst_reg /= expected.dst_exp then
                report "Random test " & integer'image(i) & ": dst_reg mismatch. Expected " & 
                       to_string(expected.dst_exp) & ", got " & to_string(dst_reg) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            if immediate_value /= expected.imm_exp then
                report "Random test " & integer'image(i) & ": immediate_value mismatch. Expected " & 
                       to_string(expected.imm_exp) & ", got " & to_string(immediate_value) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            if halt /= expected.halt_exp then
                report "Random test " & integer'image(i) & ": halt mismatch. Expected " & 
                       to_string(expected.halt_exp) & ", got " & to_string(halt) & 
                       " for instruction " & to_string(fetched_instruction) severity error;
                errors := errors + 1;
            end if;
            wait for 5 ns;
        end loop;

        -- Report results
        if errors = 0 then
            report "All tests passed successfully." severity note;
        else
            report "Test completed with " & integer'image(errors) & " errors." severity error;
        end if;
        wait;
    end process;
end architecture;