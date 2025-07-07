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
		instruction_type : in std_logic_vector(1 downto 0);
		alu_op : in std_logic_vector(2 downto 0);
		jump_condition : in std_logic_vector(2 downto 0);
		dst_reg_i : in std_logic_vector(2 downto 0);

		--! ALU operand A register, wired to R1
		alu_operand_a : in std_logic_vector(7 downto 0);

		--! Source register, either R2 for ALU or R3 for jump/branch.
		source_register : in std_logic_vector(7 downto 0);

		--! Immediate value, used for load immediate instructions
		immediate_value : in std_logic_vector(5 downto 0);

		dst_reg_o : out std_logic_vector(2 downto 0);
		--! Result or source register to write back to the destination register
		result_register : out std_logic_vector(7 downto 0);
		--! Condition result, set to '1' if the condition is met
		condition_result : out std_logic
	);
end entity execute;

architecture rtl of execute is

	signal alu_result : std_logic_vector(7 downto 0);
	signal logic_alu_result : std_logic_vector(7 downto 0);
	signal barrel_shift_result : std_logic_vector(7 downto 0);

begin

	-- Pass the destination register address to the output
	dst_reg_o <= dst_reg_i; 

	alu_result <= logic_alu_result when alu_op /= "111" else barrel_shift_result;

	--! Select the result register based on the instruction type
	with instruction_type select
		result_register <= "00" & immediate_value   when "00",
						   alu_result               when "01",
						   source_register          when "10",
						   source_register          when "11",
						   x"00"                    when others;

	ALU_INST : entity work.alu(rtl)
		port map (
			alu_op => alu_op,
			operand_a => alu_operand_a,
			operand_b => source_register,
			result => logic_alu_result
	);

	BARREL_SHIFTER_INST : entity work.barrel_shifter(rtl)
		generic map (
			WIDTH => 8
  		)
		port map (
			input_vector => alu_operand_a,
			shift_amount => signed(source_register(3 downto 0)),
			output_vector => barrel_shift_result
	);

	JMP_CONDITION_CHECK_INST : entity work.condition(rtl)
		port map (
			condition_op => jump_condition,
			operand => signed(source_register),
			result => condition_result
	);

end architecture;