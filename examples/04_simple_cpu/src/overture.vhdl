

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity overture is
	port (
		clk_i   : in std_logic;
		reset_i : in std_logic;
		
		memory_data_i : in std_logic_vector(7 downto 0);
		memory_address_o : out std_logic_vector(7 downto 0);

		io_address_o : out std_logic_vector(7 downto 0);
		io_data_read_i : in std_logic_vector(7 downto 0);
		io_data_write_o : out std_logic_vector(7 downto 0);
		io_data_write_enable_o : out std_logic;

		cpu_halted_o : out std_logic
	);
end entity overture;

architecture rtl of overture is
	signal perform_jump_EX_FE			: std_logic;
	signal jump_address_RF_FE			: std_logic_vector(7 downto 0);
	signal cpu_halt_DE_FE				: std_logic;
	signal fetched_instruction_FE_DE	: std_logic_vector(7 downto 0);
	signal instruction_type_DE_EX		: std_logic_vector(1 downto 0);
	signal instruction_type_EX_WB		: std_logic_vector(1 downto 0);
	signal immediate_value_DE_EX		: std_logic_vector(5 downto 0);
	signal alu_op_DE_EX					: std_logic_vector(2 downto 0);
	signal jump_condition_DE_EX			: std_logic_vector(2 downto 0);
	signal src_reg_addr_DE_RF			: std_logic_vector(2 downto 0);
	signal dst_reg_addr_DE_EX			: std_logic_vector(2 downto 0);
	signal dst_reg_addr_EX_WB			: std_logic_vector(2 downto 0);
	signal result_data_EX_WB			: std_logic_vector(7 downto 0);
	signal alu_operand_a_RF_EX			: std_logic_vector(7 downto 0);
	signal source_register_EX			: std_logic_vector(7 downto 0);
	signal read_register_RF_EX			: std_logic_vector(7 downto 0);
	signal register_write_enable_WB_RF	: std_logic;
	signal write_address_WB_RF			: std_logic_vector(2 downto 0);
	signal write_data_WB_RF				: std_logic_vector(7 downto 0);
begin

	cpu_halted_o <= cpu_halt_DE_FE;

	FETCH_UNIT : entity work.fetch(rtl)
		port map (
			clk_i					=> clk_i,
			reset_i					=> reset_i,
			perform_jump_i			=> perform_jump_EX_FE,
			jump_address_i			=> jump_address_RF_FE,
			halt_i					=> cpu_halt_DE_FE,
			memory_data_i			=> memory_data_i,
			memory_address_o		=> memory_address_o,
			fetched_instruction_o	=> fetched_instruction_FE_DE
	);

	DECODE_UNIT : entity work.decode(rtl)
		port map (
			fetched_instruction_i	=> fetched_instruction_FE_DE,
			instruction_type_o		=> instruction_type_DE_EX,
			alu_op_o				=> alu_op_DE_EX,
			jump_condition_o		=> jump_condition_DE_EX,
			src_reg_o				=> src_reg_addr_DE_RF,
			dst_reg_o				=> dst_reg_addr_DE_EX,
			immediate_value_o		=> immediate_value_DE_EX,
			halt_o					=> cpu_halt_DE_FE
	);

	source_register_EX <= io_data_read_i when src_reg_addr_DE_RF = "111" else read_register_RF_EX;

	EXECUTE_UNIT : entity work.execute(rtl)
		port map (
			instruction_type_i => instruction_type_DE_EX,
			alu_op_i => alu_op_DE_EX,
			jump_condition_i => jump_condition_DE_EX,
			dst_reg_i => dst_reg_addr_DE_EX,
			alu_operand_a_i => alu_operand_a_RF_EX,
			source_register_i => source_register_EX,
			immediate_value_i => immediate_value_DE_EX,
			instruction_type_o => instruction_type_EX_WB,
			dst_reg_o => dst_reg_addr_EX_WB,
			result_data_o => result_data_EX_WB,
			condition_result_o => perform_jump_EX_FE
	);

	REGISTER_FILE : entity work.registers(rtl)
		port map (
			clk				=> clk_i,
			reset			=> reset_i,
			write_address	=> write_address_WB_RF,
			write_data		=> write_data_WB_RF,
			write_enable	=> register_write_enable_WB_RF,
			read_address	=> src_reg_addr_DE_RF,
			read_data		=> read_register_RF_EX,
			jump_address	=> jump_address_RF_FE,
			alu_operand_a	=> alu_operand_a_RF_EX,
			io_address		=> io_address_o
	);

	WRITE_BACK_UNIT : entity work.write_back
	port map (
    	instruction_type_i			=> instruction_type_EX_WB,
    	dst_reg_i					=> dst_reg_addr_EX_WB,
    	result_data_i				=> result_data_EX_WB,
		register_data_o				=> write_data_WB_RF,
    	registers_write_enable_o	=> register_write_enable_WB_RF,
    	registers_write_address_o	=> write_address_WB_RF,
    	io_data_o					=> io_data_write_o,
    	io_data_write_enable_o		=> io_data_write_enable_o
);

end architecture;
