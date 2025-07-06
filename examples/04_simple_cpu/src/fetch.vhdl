-- TEROSHDL Documentation:
--! @title Fetch Unit
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 06.07.2025
--! @brief Fetch Unit for a simple CPU
--!
--! This VHDL code implements a simple fetch unit for a CPU.
--! It includes a program counter that fetches instructions from memory and handles jumps and halts.
--! The fetch unit is designed to work with an 8-bit instruction set architecture, where the program counter can hold addresses from 0 to 255.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is
	port (
		--! Clock signal
		clk					: in std_logic;
		--! Active-high, synchronous reset signal
		reset				: in std_logic;
		
		-- Inputs
		--! Active-high signal to load jump_address to the program counter
		perform_jump		: in std_logic;
		--! Jump address to load into the program counter when perform_jump is asserted
		jump_address		: in std_logic_vector(7 downto 0);
		--! Active-high signal to halt the program counter
		halt				: in std_logic;
		--! Memory data input, representing the fetched instruction from memory
		memory_data			: in std_logic_vector(7 downto 0);

		-- Outputs
		--! Memory address output, representing the current program counter value
		memory_address		: out std_logic_vector(7 downto 0);
		--! Fetched instruction output, representing the instruction fetched from memory
		fetched_instruction : out std_logic_vector(7 downto 0)
	);
end entity fetch;

architecture rtl of fetch is

	--! Internal signal to hold the program counter value
	signal program_counter_reg : unsigned(7 downto 0);

begin

	--! Program Counter process to manage the instruction fetch cycle
	PROGRAM_COUNTER : process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				-- Reset the program counter to zero on reset signal
				program_counter_reg <= (others => '0');
			else
				if halt = '1' then
					-- If halt is asserted, keep the current program counter value
					program_counter_reg <= program_counter_reg;
				else
					if perform_jump = '1' then
						-- If a jump is requested, set the program counter to the jump address
						program_counter_reg <= unsigned(jump_address);
					else
						-- Otherwise, increment the program counter to fetch the next instruction
						program_counter_reg <= program_counter_reg + 1;
					end if;
				end if;
			end if;
		end if;
	end process PROGRAM_COUNTER;

	-- Output the current program counter value as memory address
	memory_address <= std_logic_vector(program_counter_reg);

	-- Fetch the instruction from memory and output it
	fetched_instruction <= memory_data;

end architecture;