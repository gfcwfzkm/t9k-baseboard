-- TEROSHDL Documentation:
--! @title Execute Unit
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Execute Unit for a simple CPU
--!
--! This VHDL code implements a execute unit for a CPU.
--! It either just forwards an immediate value to the next stage,
--! performs an ALU operation (includes barrel_shift), checks a condition for a jump or branch, 
--! or simply copies a value from one register to another.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute is
    port (
		--! Instruction type, used to determine the operation to perform
        instruction_type_i  : in std_logic_vector(1 downto 0);
		--! ALU operation, used to determine the ALU function to perform
        alu_op_i            : in std_logic_vector(2 downto 0);
		--! Jump condition, used to determine if a jump or branch should be taken
        jump_condition_i    : in std_logic_vector(2 downto 0);
		--! Destination register address, passed on to the next stage (dst_reg_o)
        dst_reg_i           : in std_logic_vector(2 downto 0);
        --! ALU operand A register, wired to R1
        alu_operand_a_i     : in std_logic_vector(7 downto 0);
        --! Source register, either R2 for ALU or R3 for jump/branch.
        source_register_i   : in std_logic_vector(7 downto 0);
        --! Immediate value, used for load immediate instructions
        immediate_value_i   : in std_logic_vector(5 downto 0);

		--! Instruction type forwarded to the next stage
		instruction_type_o  : out std_logic_vector(1 downto 0);
		--! Destination register address forwarded to the next stage
        dst_reg_o           : out std_logic_vector(2 downto 0);
        --! Result or source register to write back to the destination register
        result_data_o       : out std_logic_vector(7 downto 0);
        --! Condition result, set to '1' if the condition is met
        condition_result_o  : out std_logic
    );
end entity execute;

architecture rtl of execute is

    signal alu_result : std_logic_vector(7 downto 0);
    signal logic_alu_result : std_logic_vector(7 downto 0);
    signal barrel_shift_result : std_logic_vector(7 downto 0);

begin

    -- Pass the destination register address to the output
    dst_reg_o <= dst_reg_i; 
	-- Pass the instruction type to the output
	instruction_type_o <= instruction_type_i;

	-- Wire the output to the barrel shifter if the ALU operation is a shift, 
	-- otherwise use the logic ALU result
    alu_result <= logic_alu_result when alu_op_i /= "111" else barrel_shift_result;

    -- Select the result register based on the instruction type
    with instruction_type_i select
        result_data_o <= "00" & immediate_value_i   when "00",
                         alu_result               when "01",
                         source_register_i          when "10",
                         source_register_i          when "11",
                         x"00"                    when others;

	--! ALU entity to perform most operations (logic & arithmetic)
    ALU_INST : entity work.alu(rtl)
        port map (
            alu_op_i => alu_op_i,
            operand_a_i => alu_operand_a_i,
            operand_b_i => source_register_i,
            result_o => logic_alu_result
    );

	--! Barrel shifter entity to perform shifts
    BARREL_SHIFTER_INST : entity work.barrel_shifter(rtl)
        generic map (
            WIDTH => 8
          )
        port map (
            input_vector_i => alu_operand_a_i,
            shift_amount_i => signed(source_register_i(3 downto 0)),
            output_vector_o => barrel_shift_result
    );

	--! Condition check entity to evaluate jump conditions
    JMP_CONDITION_CHECK_INST : entity work.condition(rtl)
        port map (
            condition_op_i => jump_condition_i,
            operand_i => signed(source_register_i),
            result_o => condition_result_o
    );

end architecture;