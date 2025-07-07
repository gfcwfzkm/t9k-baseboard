library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fetch is
end entity tb_fetch;

architecture tb of tb_fetch is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
	signal tb_finished          : boolean := false;
    signal clk                  : std_logic := '0';
    signal reset                : std_logic := '0';
    signal perform_jump         : std_logic := '0';
    signal jump_address         : std_logic_vector(7 downto 0) := (others => '0');
    signal halt                 : std_logic := '0';
    signal memory_data          : std_logic_vector(7 downto 0) := (others => '0');
    signal memory_address       : std_logic_vector(7 downto 0);
    signal fetched_instruction  : std_logic_vector(7 downto 0);

begin
    -- Instantiate DUT
    dut : entity work.fetch
        port map (
            clk                 => clk,
            reset               => reset,
            perform_jump        => perform_jump,
            jump_address        => jump_address,
            halt                => halt,
            memory_data         => memory_data,
            memory_address      => memory_address,
            fetched_instruction => fetched_instruction
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2 when not tb_finished else '0';

    -- Test process
    test_proc : process
        -- Helper procedure to check outputs
        procedure check_outputs(
            exp_addr : natural;
            exp_instr : std_logic_vector(7 downto 0)
		) is
        begin
            assert memory_address = std_logic_vector(to_unsigned(exp_addr, 8))
                report "Address error! Expected: " & to_string(exp_addr) & 
                       " Got: " & to_string(to_integer(unsigned(memory_address)))
                severity error;
            assert fetched_instruction = exp_instr
                report "Instruction error! Expected: " & to_string(exp_instr) & 
                       " Got: " & to_string(fetched_instruction)
                severity error;
        end procedure;
    begin
        -- Initialize and reset
        reset <= '1';
        memory_data <= (others => '0');
        wait for CLK_PERIOD;
        check_outputs(0, "00000000");  -- After reset
        
        -- Test normal operation (incrementing)
        reset <= '0';
        for i in 1 to 5 loop
            memory_data <= std_logic_vector(unsigned(memory_data) + 1);
            wait for CLK_PERIOD;
            check_outputs(i, std_logic_vector(to_unsigned(i, 8)));
        end loop;
        
        -- Test halt functionality
        halt <= '1';
        wait for CLK_PERIOD;
        check_outputs(5, "00000101");  -- PC should stay at 5
        halt <= '0';
        
        -- Continue normal operation
        memory_data <= "00000110";
        wait for CLK_PERIOD;
        check_outputs(6, "00000110");
        
        -- Test jump functionality
        perform_jump <= '1';
        jump_address <= "10101010";  -- AA hex
        memory_data <= "11110000";    -- F0 hex
        wait for CLK_PERIOD;
        check_outputs(16#AA#, "11110000");
        
        -- Test jump with halt (halt should override)
        perform_jump <= '1';
        halt <= '1';
        jump_address <= "01010101";   -- 55 hex
        memory_data <= "00001111";    -- 0F hex
        wait for CLK_PERIOD;
        check_outputs(16#AA#, "00001111");  -- PC remains at AA
        halt <= '0';
        
        -- Test post-jump increment
        perform_jump <= '0';
        memory_data <= "10101010";
        wait for CLK_PERIOD;
        check_outputs(16#AB#, "10101010");
        
        -- Test reset during operation
        reset <= '1';
        wait for CLK_PERIOD;
        check_outputs(0, "10101010");  -- Address resets, instruction remains
        
        -- Test reset release
        reset <= '0';
        memory_data <= "11001100";
        wait for CLK_PERIOD;
        check_outputs(1, "11001100");
        
        report "Testbench completed";
		tb_finished <= true;
        wait;
    end process test_proc;

end architecture tb;