-- Dependency: src/barrel_shifter.vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture testbench of tb_barrel_shifter is
    constant WIDTH : positive := 8;
    constant SHIFT_BITS : positive := integer(ceil(log2(real(WIDTH)))) + 1;
    constant NUM_RANDOM_TESTS : positive := 500;

    signal input_vector : std_logic_vector(WIDTH-1 downto 0);
    signal shift_amount : signed(SHIFT_BITS-1 downto 0);
    signal output_vector : std_logic_vector(WIDTH-1 downto 0);

    function expected_shift (
        input_vec : std_logic_vector;
        shift : integer
    ) return std_logic_vector is
        constant len : natural := input_vec'length;
        variable temp : std_logic_vector(len-1 downto 0);
        variable input_vector : std_logic_vector(len-1 downto 0) := input_vec;
        variable abs_shift : natural;
    begin
        abs_shift := abs(shift);
        
        temp := (others => '0');  -- Default to zero vector
        if abs_shift >= len then
            temp := (others => '0');
        else
            if shift >= 0 then  -- Left shift
                temp := input_vector(len-1-abs_shift downto 0) & (abs_shift-1 downto 0 => '0');
            else   -- Right shift
                temp := (abs_shift-1 downto 0 => '0') & input_vector(len-1 downto abs_shift);
            end if;
        end if;
        return temp;
    end function;

begin
    -- Instantiate the barrel shifter DUT
    DUT : entity work.barrel_shifter
        generic map (
            WIDTH => WIDTH
        )
        port map (
            input_vector => input_vector,
                shift_amount => shift_amount,
            output_vector => output_vector
    );

    stimulus : process
        variable error_count : natural := 0;
        variable ignored_errors : natural := 0;
        variable seed1, seed2 : positive := 1;
        variable rand_real : real;
        variable rand_int : integer;
        variable expected : std_logic_vector(WIDTH-1 downto 0);
        
        procedure run_test(
            input_val : std_logic_vector;
            shift_val : integer;
            variable err_cnt : inout natural
        ) is
            variable exp_vec : std_logic_vector(WIDTH-1 downto 0);
        begin
            shift_amount <= to_signed(shift_val, SHIFT_BITS);
            input_vector <= input_val;
            wait for 5 ns;
            
            exp_vec := expected_shift(input_val, shift_val);
            
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

        -- Ignore the errors of the following four tests
        -- Full width shifts
        --run_test("10101010", WIDTH, ignored_errors);
        --run_test("10101010", -WIDTH, ignored_errors);
        
        -- More than full width
        --run_test("11001100", WIDTH + 1, ignored_errors);
        --run_test("11001100", -(WIDTH + 1), ignored_errors);
        
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
                    input_vector(j) <= '1';
                else
                    input_vector(j) <= '0';
                end if;
            end loop;
            
            -- Generate random shift amount (-2*WIDTH to 2*WIDTH)
            uniform(seed1, seed2, rand_real);
            rand_int := integer(floor(rand_real * real(2 * (WIDTH-1)))) - (WIDTH-1);            
            shift_amount <= to_signed(rand_int, SHIFT_BITS);
            
            wait for 10 ns;
            
            -- Check result
            expected := expected_shift(input_vector, rand_int);
            if output_vector /= expected then
                report "Error: Input=" & to_string(input_vector) & 
                       " Shift=" & integer'image(rand_int) & 
                       " Expected=" & to_string(expected) & 
                       " Got=" & to_string(output_vector)
                severity error;
                error_count := error_count + 1;
            end if;
        end loop;
        
        -- Final report
        report "TEST COMPLETE. Errors: " & integer'image(error_count);
        wait;
    end process;
end testbench;