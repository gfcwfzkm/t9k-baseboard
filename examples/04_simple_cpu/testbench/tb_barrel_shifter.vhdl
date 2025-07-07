-- Dependency: src/barrel_shifter.vhdl
-- TEROSHDL Documentation:
--! @title Barrel Shifter Testbench
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 07.07.2025
--! @brief Testbench for the barrel shifter
--!
--! This testbench verifies the functionality of a barrel shifter.
--! It goes through edge cases and special patterns, and then runs a number of random tests.
--! 
--! The amount of random tests can be configured by changing the `NUM_RANDOM_TESTS` constant.
--! 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture testbench of tb_barrel_shifter is
	--! Bit-Width of the barrel shifter
    constant WIDTH : positive := 8;
	--! Number of bits needed to represent the shift amount
    constant SHIFT_BITS : positive := integer(ceil(log2(real(WIDTH)))) + 1;
	--! Number of random tests to run
    constant NUM_RANDOM_TESTS : positive := 500;

	--! Input vector going into the barrel shifter
    signal input_vector : std_logic_vector(WIDTH-1 downto 0);
	--! Shift amount (signed, two's complement) to shift the input vector
    signal shift_amount : signed(SHIFT_BITS-1 downto 0);
	--! Output vector from the barrel shifter
    signal output_vector : std_logic_vector(WIDTH-1 downto 0);

	--! Function to calculate the expected output of the barrel shifter
    function expected_shift (
        input_vec : std_logic_vector;
        shift : integer
    ) return std_logic_vector is
        constant len : natural := input_vec'length;
        variable temp : std_logic_vector(len-1 downto 0);
        variable input_vector : std_logic_vector(len-1 downto 0) := input_vec;
        variable abs_shift : natural;
    begin
        abs_shift := abs(shift) mod len;
        
        temp := (others => '0');  -- Default to zero vector
        
		if shift >= 0 then  -- Left shift
            temp := input_vector(len-1-abs_shift downto 0) & (abs_shift-1 downto 0 => '0');
        else   -- Right shift
            temp := (abs_shift-1 downto 0 => '0') & input_vector(len-1 downto abs_shift);
        end if;

        return temp;
    end function;

begin
    --! Instantiate the barrel shifter DUT
    DUT : entity work.barrel_shifter
        generic map (
            WIDTH => WIDTH
        )
        port map (
            input_vector => input_vector,
            shift_amount => shift_amount,
            output_vector => output_vector
    );

	--! Stimulus process to apply test vectors
    stimulus : process
        variable error_count : natural := 0;
        variable seed1, seed2 : positive := 42;
        variable rand_real : real;
        variable rand_int : integer;
		variable rand_input_vector : std_logic_vector(WIDTH-1 downto 0);
        
		--! Procedure to run a test case and check the output
        procedure run_test(
            input_val : std_logic_vector;
            shift_val : integer;
            variable err_cnt : inout natural
        ) is
            variable exp_vec : std_logic_vector(WIDTH-1 downto 0);
			variable sh_amount : signed(7 downto 0);
        begin
            sh_amount := to_signed(shift_val, sh_amount'length);

            shift_amount <= sh_amount(SHIFT_BITS-1 downto 0);
            input_vector <= input_val;
            wait for 5 ns;
            
            exp_vec := expected_shift(input_val, to_integer(shift_amount));
            
            if output_vector /= exp_vec then
                report "Error: Input=" & to_string(input_val) & 
                       " Shift=" & integer'image(shift_val) & 
                       " Expected=" & to_string(exp_vec) & 
                       " Got=" & to_string(output_vector)
                severity error;
                err_cnt := err_cnt + 1;
            end if;
            wait for 5 ns;
        end procedure;

    begin
        -- Edge case tests
        report "Testing shifter function...";
        wait for 10 ns;
        -- Zero shift
        run_test("00000000", 0, error_count);
        run_test("11111111", 0, error_count);
        run_test("10101010", 0, error_count);
        
        -- Single bit shifts
        run_test("10000000", 1, error_count);
        run_test("10000000", -1, error_count);
        run_test("00000001", 1, error_count);
        run_test("00000001", -1, error_count);
        
        -- Special patterns
        run_test("10000001", 3, error_count);
        run_test("10000001", -3, error_count);
        run_test("10101010", 4, error_count);
        run_test("10101010", -4, error_count);

        -- Boundary shifts
        run_test("11111111", WIDTH - 1, error_count);
        run_test("11111111", -(WIDTH - 1), error_count);

        -- Ignore the errors of the following four tests as they are expected to fail
        -- Full width shifts
        run_test("10101010", WIDTH, error_count);
        run_test("10101010", -WIDTH, error_count);
        
        -- More than full width
        run_test("11001100", WIDTH + 1, error_count);
        run_test("11001100", -(WIDTH + 1), error_count);
        
        -- If we can't even pass the edge case tests, we don't even want to run the random tests
        if error_count > 0 then
            report "Some edge case tests failed. Errors: " & integer'image(error_count) severity failure;
        end if;
        
        -- Random tests
        report "Testing " & integer'image(NUM_RANDOM_TESTS) & " random cases...";
        for i in 1 to NUM_RANDOM_TESTS loop
            -- Generate random input vector
            for j in 0 to WIDTH-1 loop
                uniform(seed1, seed2, rand_real);
                if rand_real > 0.5 then
                    rand_input_vector(j) := '1';
                else
                    rand_input_vector(j) := '0';
                end if;
            end loop;
            
            -- Generate random shift amount (-(WIDTH-1) to (WIDTH-1))
            uniform(seed1, seed2, rand_real);
            rand_int := integer(floor(rand_real * real(2 * (WIDTH-1)))) - (WIDTH-1);
            
			-- Apply the input vector and check the output
			run_test(rand_input_vector, rand_int, error_count);
        end loop;
        
        -- Final report
        report "TEST COMPLETE. Errors: " & integer'image(error_count);
        wait;
    end process;
end testbench;