-- TEROSHDL Documentation:
--! @title Decode Unit
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Decode Unit for a simple CPU
--!
--! This VHDL code implements a simple decode unit for a CPU.
--! It decodes the fetched instruction into control signals for the ALU and register addresses.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
    port (
        --! Fetched instruction input to decode into control signals
        fetched_instruction_i   : in std_logic_vector(7 downto 0);

        --! Instruction type
        instruction_type_o      : out std_logic_vector(1 downto 0);
        --! Decoded ALU operation
        alu_op_o                : out std_logic_vector(2 downto 0);
        --! Jump/Branch condition
        jump_condition_o        : out std_logic_vector(2 downto 0);
        --! Source register address
        src_reg_o               : out std_logic_vector(2 downto 0);
        --! Destination register address
        dst_reg_o               : out std_logic_vector(2 downto 0);
        --! Immediate value from the instruction
        immediate_value_o       : out std_logic_vector(5 downto 0);

        --! Halt signal to stop the CPU, if an illegal instruction is encountered
        halt_o                  : out std_logic
    );
end entity decode;

architecture rtl of decode is
begin

    -- Decode the respective fields from the fetched instruction
    instruction_type_o <= fetched_instruction_i(7 downto 6); -- Instruction type bits

    --! Decode process for the fetched instruction
    process (instruction_type_o, fetched_instruction_i) is
    begin
        src_reg_o         <= "000"; -- Source register bits
        dst_reg_o         <= "000"; -- Destination register bits
        alu_op_o          <= "000"; -- Default ALU operation to OR operation
        jump_condition_o  <= "000"; -- Jump/Branch condition bits to never-branch by default
        immediate_value_o <= "000000"; -- Default immediate value to zero
        halt_o            <= '0'; -- Default halt signal to '0' (not halted)

        -- Instruction types:
        -- 00IIIIII - Load Immediate I (6 bits immediate value) into R0
        -- 01000AAA - ALU/Compute Instruction A (3 bits ALU) on R1 and R2, result in R3
        -- 10SSSDDD - Copy Instruction S (3 bits source) to D (3 bits destination)
        -- 11000CCC - Jump/Branch Instruction C (3 bits condition) to R0 if condition in R3 is met
        --
        -- If a unknown instruction is encountered (particular for the ALU and jump/branch instructions),
        -- we set the halt signal to '1' to stop the CPU. The Program Counter will not increment
        -- and the CPU will wait for a reset signal to continue.

        case instruction_type_o is
            when "00" => -- Load Immediate Instruction Type
                -- Load the immediate value into the register R0, so
                -- the dst_reg is set to R0
                dst_reg_o <= std_logic_vector(to_unsigned(0,3));
                 -- Immediate value from the instruction
                immediate_value_o <= fetched_instruction_i(5 downto 0);

            when "01" => -- ALU/Compute Instruction Type
                -- ALU operation, operand A is hard-wired to R1 but
                -- operand B is the value in the src_reg - wired to R2
                -- dst_reg is the result register, which is R3

                -- Bits 3 to 5 are unused and expected to be zero. If not, illegal instruction
                if fetched_instruction_i(5 downto 3) /= "000" then
                    halt_o <= '1'; -- Set halt signal to stop the CPU if ALU operation is not valid
                else
                    src_reg_o <= std_logic_vector(to_unsigned(2,3)); -- R2 as operand A
                    dst_reg_o <= std_logic_vector(to_unsigned(3,3)); -- R3 as result register
                    alu_op_o <= fetched_instruction_i(2 downto 0);   -- ALU operation bits
                end if;

            when "10" => -- Copy Instruction Type
                src_reg_o <= fetched_instruction_i(5 downto 3); -- Source register bits
                dst_reg_o <= fetched_instruction_i(2 downto 0); -- Destination register bits

            when "11" => -- Jump/Branch Instruction Type
                -- For jump or branch instructions, we check the condition in
                -- R3 and if the condition is met, we jump to the address in R0
                -- So, src_reg is set to R3 while the program counter has direct
                -- to the R0 register
                if fetched_instruction_i(5 downto 3) /= "000" then
                    halt_o <= '1'; -- Set halt signal to stop the CPU if condition is not met
                else
                    src_reg_o <= std_logic_vector(to_unsigned(3,3)); -- R3 for condition check
                    jump_condition_o <= fetched_instruction_i(2 downto 0); -- Jump/Branch condition bits
                end if;
                
            when others =>
                -- default case, assert halt signal
                halt_o <= '1'; -- Set halt signal to stop the CPU
        end case;
    end process;

    

end architecture;