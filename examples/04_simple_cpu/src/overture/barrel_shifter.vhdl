-- TEROSHDL Documentation:
--! @title Barrel Shifter
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Simple, generic barrel shifter (logic shift)
--!
--! This VHDL code implements a simple barrel shifter that can perform left and right 
--! shifts on an input vector. The direction of the shift is determined by the sign of the
--! shift amount: positive values indicate a left shift, while negative values indicate a right shift.
--!
--! The barrel shifter allows shifts from WIDTH-1 (left shift) to -WIDTH+1 (right shift).
--! If WIDTH is set to 9, this means the shifter can shift 7 bits to the left or 7 bits to the right.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity barrel_shifter is
    generic  (
        --! Width of the input vector
        WIDTH : positive := 8
    );
    port (
        --! Input vector to be shifted
        input_vector_i  : in std_logic_vector(WIDTH - 1 downto 0);
        --! Shift amount, can be positive (left shift) or negative (right shift)
        shift_amount_i  : in signed(integer(ceil(log2(real(WIDTH)))) downto 0);
        
        --! Output vector after shifting
        output_vector_o : out std_logic_vector(WIDTH - 1 downto 0)
    );
end entity barrel_shifter;

architecture rtl of barrel_shifter is

    --! Maximum shift amount based on the width of the input vector
    constant MAX_SHIFT : POSITIVE := integer(ceil(log2(real(WIDTH))));

    --! Signal to hold the reversed input vector for left shifts
    signal input_vector_reversed : std_logic_vector(WIDTH - 1 downto 0);
    --! Signal to hold the reversed output vector for left shifts
    signal output_vector_reversed : std_logic_vector(WIDTH - 1 downto 0);

    --! Signal to determine the shift direction: '1' for left, '0' for right
    signal shift_direction_left : std_logic;
    --! Signal to hold the absolute value of the shift amount
    signal shift_amount_abs : unsigned(MAX_SHIFT downto 0);

    --! Type and signal to hold intermediate results during the shifting process
    type t_interm_vector is array (integer range 0 to MAX_SHIFT) of std_logic_vector(WIDTH - 1 downto 0);
    signal intermediate_vector : t_interm_vector;

    --! Type and signal to hold the bitmask for each shift stage
    type t_bitshift_vector is array (integer range 0 to MAX_SHIFT - 1) of unsigned(MAX_SHIFT - 1 downto 0);
    signal bitshift_vector : t_bitshift_vector := (others => (others => '0'));

begin

    -- Determine the shift direction and absolute shift amount
    shift_direction_left <= not shift_amount_i(shift_amount_i'length - 1);
    shift_amount_abs <= unsigned(abs(shift_amount_i));

    -- Reverse the input vector, needed for left shifts
    REVERSE_INPUT : for i in 0 to WIDTH-1 generate
        input_vector_reversed(WIDTH - 1 - i) <= input_vector_i(i);
    end generate;

    -- Initialize the intermediate vector
    intermediate_vector(0) <= input_vector_reversed when shift_direction_left = '1' else
                              input_vector_i;

    -- Perform the shifts
    BARREL_SHIFT : for i in MAX_SHIFT-1 downto 0 generate
        -- Helper signal to store the bitmask for the current shift stage
        bitshift_vector(i) <= shift_left(to_unsigned(1, MAX_SHIFT), i);

        -- Shift stage
        SHIFT_STAGE : for j in 0 to WIDTH - 1 generate
            intermediate_vector(i+1)(j) <= intermediate_vector(i)(j)                                  when shift_amount_abs(i) = '0' else
                                           intermediate_vector(i)(j + to_integer(bitshift_vector(i))) when j < (WIDTH - to_integer(bitshift_vector(i))) else
                                           '0';
        end generate;
    end generate;
    
    -- Reverse the output vector, needed for left shifts
    REVERSE_OUTPUT : for i in 0 to WIDTH-1 generate
        output_vector_reversed(WIDTH - 1 - i) <= intermediate_vector(MAX_SHIFT)(i);
    end generate;

    -- Assign the final output vector
    output_vector_o <= output_vector_reversed when shift_direction_left = '1' else
                     intermediate_vector(MAX_SHIFT);

end architecture;