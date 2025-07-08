-- TEROSHDL Documentation:
--! @title Overture (Simple CPU)
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 08.07.2025
--! @brief Top-level entity for the simple Overture CPU
--!
--! This VHDL code implements the top-level entity for a simple CPU called Overture from the game "Turing Complete".
--! It includes the fetch, decode, execute, register file, and write-back units.
--! The CPU is designed to work with an 8-bit instruction set architecture
--! and supports basic operations such as arithmetic, logic, jumps, and memory access.
--!
--! The CPU has no RAM but it can be implemented through the I/O interface.
--! The memory interface supports up to 256 bytes of read-only memory, while
--! the I/O interface allows to read and write up to 256 bytes of data / addresses.
--!
--! The ISA has four types of instructions:
--! - Load Immediate: Loads a 6-bit immediate value into a register.
--! - Arithmetic Operations: Performs arithmetic operations on registers.
--! - Copy Operations: Copies data between registers or from/to I/O.
--! - Jump Operations: Jumps to a specified address based on conditions.
--!
--! The CPU has 7 accessible registers (R0 to R6) and a program counter (PC), with
--! some of the registers serving special purposes:
--! - R0: Used for immediate values and as a jump address.
--! - R1: Used as the first operand for arithmetic operations.
--! - R2: Used as the second operand for arithmetic operations.
--! - R3: Used to store the result of arithmetic operations.
--! - R4: General-purpose register, can be used for any purpose.
--! - R5: General-purpose register, can be used for any purpose.
--! - R6: Used for I/O address
--!
--! The full Instruction Set is as follows:
--! - `00II IIII`: Load Immediate (`I` = 6-bit immediate value) into R0
--! - `0100 0AAA`: Arithmetic Operation (`A` = 3-bit ALU operation) on R1 and R2, result in R3
--! - - `0100 0000`: OR Operation (R3 = R1 | R2)
--! - - `0100 0001`: NAND Operation (R3 = ~(R1 & R2))
--! - - `0100 0010`: NOR Operation (R3 = ~(R1 | R2))
--! - - `0100 0011`: AND Operation (R3 = R1 & R2)
--! - - `0100 0100`: ADD Operation (R3 = R1 + R2)
--! - - `0100 0101`: SUB Operation (R3 = R1 - R2)
--! - - `0100 0110`: XOR Operation (R3 = R1 ^ R2)
--! - - `0100 0111`: SHIFT Operation (R3 = R1 << R2 if R2 >= 0, otherwise R3 = R1 >> R2)
--! - `10SS SDDD`: Copy Operation (`S` = 3-bit source register, `D` = 3-bit destination register)
--! - `1100 0CCC`: Jump Operation (`C` = 3-bit condition code), `PC` = R0 if condition `C` is met on R3
--! - - `1100 0000`: Never jump (bascially a NOP)
--! - - `1100 0001`: Jump if zero (R3 == 0)
--! - - `1100 0010`: Jump if less than zero (R3 < 0)
--! - - `1100 0011`: Jump if less than or equal to zero (R3 <= 0)
--! - - `1100 0100`: Always jump (unconditional jump)
--! - - `1100 0101`: Jump if not zero (R3 != 0)
--! - - `1100 0110`: Jump if greater than or equal to zero (R3 >= 0)
--! - - `1100 0111`: Jump if greater than zero (R3 > 0)
--! 
--! In total the CPU supports 18 instructions.
--!
--! Illegal instructions will cause the CPU to halt, requiring a reset to recover.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity overture is
    port (
        --! Clock signal
        clk_i                   : in std_logic;
        --! Active-high, synchronous reset signal
        reset_i                 : in std_logic;
        
        --! Instruction Read-Only Memory (ROM) data input
        memory_data_i           : in std_logic_vector(7 downto 0);
        --! Memory address output for instruction fetch
        memory_address_o        : out std_logic_vector(7 downto 0);

        --! I/O address output for reading/writing data
        io_address_o            : out std_logic_vector(7 downto 0);
        --! I/O data read input for reading data from I/O
        io_data_read_i          : in std_logic_vector(7 downto 0);
        --! I/O data write output for writing data to I/O
        io_data_write_o         : out std_logic_vector(7 downto 0);
        --! I/O data write enable output for controlling write operations to I/O
        io_data_write_enable_o  : out std_logic;

        --! Halted CPU output signal - if active, the CPU will not execute further instructions
        cpu_halted_o            : out std_logic
    );
end entity overture;

architecture rtl of overture is

    --! Jump signal, going from the execute to the fetch unit
    signal perform_jump_EX_FE           : std_logic;
    --! Jump address, going from the register file to the fetch unit
    signal jump_address_RF_FE           : std_logic_vector(7 downto 0);
    --! Signal to halt the CPU, going from the decode unit to the fetch unit
    signal cpu_halt_DE_FE               : std_logic;
    --! Memory address output, going from the fetch to the decode unit
    signal fetched_instruction_FE_DE    : std_logic_vector(7 downto 0);
    --! Instruction type, going from the decode to the execute unit
    signal instruction_type_DE_EX       : std_logic_vector(1 downto 0);
    --! Instruction type, going from the execute to the write-back unit
    signal instruction_type_EX_WB       : std_logic_vector(1 downto 0);
    --! Immediate value, going from the decode to the execute unit
    signal immediate_value_DE_EX        : std_logic_vector(5 downto 0);
    --! ALU operation, going from the decode to the execute unit
    signal alu_op_DE_EX                 : std_logic_vector(2 downto 0);
    --! Jump condition, going from the decode to the execute unit
    signal jump_condition_DE_EX         : std_logic_vector(2 downto 0);
    --! Signal to perform a jump, going from the execute unit to the Register File
    signal src_reg_addr_DE_RF           : std_logic_vector(2 downto 0);
    --! Source register address, going from the decode to the execute unit
    signal dst_reg_addr_DE_EX           : std_logic_vector(2 downto 0);
    --! Destination register address, going from the execute to the write-back unit
    signal dst_reg_addr_EX_WB           : std_logic_vector(2 downto 0);
    --! Result data, going from the execute to the write-back unit
    signal result_data_EX_WB            : std_logic_vector(7 downto 0);
    --! Result of the jump condition, going from the execute unit to the execute unit
    signal alu_operand_a_RF_EX          : std_logic_vector(7 downto 0);
    --! Result of the jump condition, assembled by the io_data_read_i signal and
    --! the read_register_RF_EX signal, going to the execute unit depending on the
    --! source register address
    signal source_register_EX           : std_logic_vector(7 downto 0);
    --! Read register address, going from the register file to the execute unit
    signal read_register_RF_EX          : std_logic_vector(7 downto 0);
    --! Write register enable signal, going from the write-back unit to the register file
    signal register_write_enable_WB_RF  : std_logic;
    --! Write register address, going from the write-back unit to the register file
    signal write_address_WB_RF          : std_logic_vector(2 downto 0);
    --! Register data, going from the write-back unit to the register file
    signal write_data_WB_RF             : std_logic_vector(7 downto 0);

begin

    cpu_halted_o <= cpu_halt_DE_FE;

    FETCH_UNIT : entity work.fetch(rtl)
        port map (
            clk_i                   => clk_i,
            reset_i                 => reset_i,
            perform_jump_i          => perform_jump_EX_FE,
            jump_address_i          => jump_address_RF_FE,
            halt_i                  => cpu_halt_DE_FE,
            memory_data_i           => memory_data_i,
            memory_address_o        => memory_address_o,
            fetched_instruction_o   => fetched_instruction_FE_DE
    );

    DECODE_UNIT : entity work.decode(rtl)
        port map (
            fetched_instruction_i   => fetched_instruction_FE_DE,
            instruction_type_o      => instruction_type_DE_EX,
            alu_op_o                => alu_op_DE_EX,
            jump_condition_o        => jump_condition_DE_EX,
            src_reg_o               => src_reg_addr_DE_RF,
            dst_reg_o               => dst_reg_addr_DE_EX,
            immediate_value_o       => immediate_value_DE_EX,
            halt_o                  => cpu_halt_DE_FE
    );

    source_register_EX <= io_data_read_i when src_reg_addr_DE_RF = "111" else read_register_RF_EX;

    EXECUTE_UNIT : entity work.execute(rtl)
        port map (
            instruction_type_i  => instruction_type_DE_EX,
            alu_op_i            => alu_op_DE_EX,
            jump_condition_i    => jump_condition_DE_EX,
            dst_reg_i           => dst_reg_addr_DE_EX,
            alu_operand_a_i     => alu_operand_a_RF_EX,
            source_register_i   => source_register_EX,
            immediate_value_i   => immediate_value_DE_EX,
            instruction_type_o  => instruction_type_EX_WB,
            dst_reg_o           => dst_reg_addr_EX_WB,
            result_data_o       => result_data_EX_WB,
            condition_result_o  => perform_jump_EX_FE
    );

    REGISTER_FILE : entity work.registers(rtl)
        port map (
            clk_i           => clk_i,
            reset_i         => reset_i,
            write_address_i => write_address_WB_RF,
            write_data_i    => write_data_WB_RF,
            write_enable_i  => register_write_enable_WB_RF,
            read_address_i  => src_reg_addr_DE_RF,
            read_data_o     => read_register_RF_EX,
            jump_address_o  => jump_address_RF_FE,
            alu_operand_a_o => alu_operand_a_RF_EX,
            io_address_o    => io_address_o
    );

    WRITE_BACK_UNIT : entity work.write_back
    port map (
        instruction_type_i          => instruction_type_EX_WB,
        dst_reg_i                   => dst_reg_addr_EX_WB,
        result_data_i               => result_data_EX_WB,
        register_data_o             => write_data_WB_RF,
        registers_write_enable_o    => register_write_enable_WB_RF,
        registers_write_address_o   => write_address_WB_RF,
        io_data_o                   => io_data_write_o,
        io_data_write_enable_o      => io_data_write_enable_o
    );

end architecture;
