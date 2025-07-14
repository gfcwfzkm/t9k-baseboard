-- TEROSHDL Documentation:
--! @title TMDS Encoder
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 15.06.2025
--! @brief Encodes the color data into TMDS format for DVI/HDMI output.
--!
--! This module encodes the color data into TMDS format, which is used for DVI and HDMI video outputs.
--! It implements the transition-minimizing encoding algorithm and DC balancing to ensure a balanced signal.
--! The control signals are also handled.
--! 
--! Make sure to use them only for the blue TMDS channel, as the
--! red and green channels carry other data when the display is not active. In this case, tie the
--! hsync and vsync signals to '0' for the red and green channels.
--!
--! The TMDS encoding process is as follows:
--! ![DVI TMDS Video Data Encode Algorithm](https://fpga.mit.edu/6205/_static/F24/assignments/hdmi/tmds_tm/flowchart.png)
--!
--! Image from https://fpga.mit.edu/6205/F24/assignments/hdmi/tmds_tm, which is from the HDMI 1.3 specs.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.helper_pkg.all;

entity tmds_encoder is
    port (
        --! Pixel Clock
        clk         : in  std_logic;
        --! Synchronous Reset signal (active-high)
        reset       : in  std_logic;

        --! Display Enable signal (active-high)
        disp_enable : in std_logic;
        --! Horizontal Sync signal (active-high)
        hsync       : in  std_logic;
        --! Vertical Sync signal (active-high)
        vsync       : in  std_logic;
        --! Color Data input (8 bits)
        color_data  : in std_logic_vector(7 downto 0);

        --! Encoded TMDS output (10 bits)
        tmds_encoded : out std_logic_vector(9 downto 0)
    );
end entity tmds_encoder;

architecture rtl of tmds_encoder is

    --! Output Register for the TMDS encoded data
    signal tmds_output_next, tmds_output_reg    : std_logic_vector(9 downto 0);

     --! DC Balancing Register to keep track of the sent 1s and 0s
    signal dc_balancing_reg, dc_balancing_next  : signed(4 downto 0);

    --! Intermediate signals for the transition-minimizing encoding
    signal xored_color_data, xnored_color_data  : std_logic_vector(7 downto 0);
begin

    xored_color_data(0) <= color_data(0);
    xnored_color_data(0) <= color_data(0);

    TRANSITION_MINIMIZING : for n in 1 to 7 generate
    begin
        xnored_color_data(n)    <= color_data(n) xor xnored_color_data(n - 1);
        xored_color_data(n)     <= color_data(n) xnor xored_color_data(n - 1);
    end generate TRANSITION_MINIMIZING;

    --! Register process to hold the TMDS output and DC balancing values
    REGCLK : process (clk, reset) begin
        if rising_edge(clk) then
            if reset = '1' then
                tmds_output_reg <= (others => '0');
                dc_balancing_reg <= to_signed(0, dc_balancing_reg'length);
            else
                tmds_output_reg <= tmds_output_next;
                dc_balancing_reg <= dc_balancing_next;
            end if;
        end if;
    end process REGCLK;
    tmds_encoded <= tmds_output_reg;

     --! Main TMDS encoding process
    NSL : process (color_data, hsync, vsync, disp_enable, tmds_output_reg, dc_balancing_reg, xored_color_data, xnored_color_data) is
        variable tmds_intermediate : std_logic_vector(8 downto 0);
        variable ones_in_color_data : natural range 0 to 8;
        variable ones_in_tmds_inter : natural range 0 to 8;
        variable zeros_in_tmds_inter : natural range 0 to 8;
    begin

        tmds_output_next <= tmds_output_reg;
        dc_balancing_next <= dc_balancing_reg;

        -- Count the ones in our color data package. Based on that, the optimal
        -- transition-minimizing method will be used.
        ones_in_color_data := count_ones(color_data);

        -- The "Transition Minimizing" part of TMDS - choose XNOR or XOR encoding
        -- based on what gives us less transitions
        DECIDE_XOR_XNOR : if (ones_in_color_data > 4) OR 
                       ((ones_in_color_data = 4) and (color_data(0) = '0')) then
            tmds_intermediate := '0' & xored_color_data;
        else
            tmds_intermediate := '1' & xnored_color_data;
        end if DECIDE_XOR_XNOR;

        -- Count the ones in the partially encoded package, excluding the XNOR/XOR bit.
        ones_in_tmds_inter := count_ones(tmds_intermediate and "011111111");
        zeros_in_tmds_inter := 8 - ones_in_tmds_inter;

        -- Is the display even active?
        if disp_enable = '0' then
            -- Nope, send the control signals based on hsync and vsync
            -- and reset the DC balancing counter
            dc_balancing_next <= to_signed(0, dc_balancing_next'length);
            if vsync = '0' and hsync = '0' then
                tmds_output_next <= "1101010100";
            elsif vsync = '0' and hsync = '1' then
                tmds_output_next <= "0010101011";
            elsif vsync = '1' and hsync = '0' then
                tmds_output_next <= "0101010100";
            else
                tmds_output_next <= "1010101011";
            end if;
        else
            -- Display *is* active! Time for the "Differential Signaling" part of TMDS

            -- Check if the dc_balancing_reg is zero *or* if there are as many zeros as ones.
            -- IF Cnt(t-1) == 0 OR N_1(tmds_inter[7:0]) == N_0(tmds_inter[7:0] THEN
            if dc_balancing_reg = 0 or ones_in_tmds_inter = 4 then
                -- First encode the final data depending if we used XNOR or XOR
                -- tmds_out[9] = ~tmds_inter[8]
                -- tmds_out[8] = tmds_inter[8]
                -- tmds_out[7:0] = (tmds_inter[8] ? tmds_inter[7:0] : ~tmds_inter[7:0])

                -- Track the amount of ones and zeros
                -- IF tmds_intermediate(8) = '1' THEN
                --    Cnt(t) = Cnt(t-1) + N_1(tmds_inter[7:0]) - N_0(tmds_inter[7:0])
                -- ELSE
                --    Cnt(t) = Cnt(t-1) - N_1(tmds_inter[7:0]) + N_0(tmds_inter[7:0])
                -- END IF
                if tmds_intermediate(8) = '1' then
                    tmds_output_next <= (not tmds_intermediate(8)) & tmds_intermediate;
                    dc_balancing_next <= dc_balancing_reg + ones_in_tmds_inter - zeros_in_tmds_inter;
                else
                    tmds_output_next <= (not tmds_intermediate(8)) & tmds_intermediate(8) & not tmds_intermediate(7 downto 0);
                    dc_balancing_next <= dc_balancing_reg - ones_in_tmds_inter + zeros_in_tmds_inter;
                end if;
            else
                -- We aren't in balance! Check if we have a lack or surplus of ones
                -- and then invert the data based on this conclusion or not
                -- IF Cnt(t-1) > 0 AND N_1(tmds_inter[7:0]) > N_0(tmds_inter[7:0] OR
                --    Cnt(t-1) < 0 AND N_0(tmds_inter[7:0]) > N_1(tmds_inter[7:0] THEN
                if (dc_balancing_reg > 0 and ones_in_tmds_inter > 4) or
                   (dc_balancing_reg < 0 and ones_in_tmds_inter < 4) then
                    -- q_out[9] = 1
                    -- q_out[8] = tmds_inter[8]
                    -- q_out[7:0] = ~tmds_inter[7:0]
                    tmds_output_next <= '1' & tmds_intermediate(8) & not tmds_intermediate(7 downto 0);
                    -- Track the amount of ones and zeros
                    -- Cnt(t) = Cnt(t-1) - 2*(~tmds_inter[8]) + N_1(tmds_inter[7:0]) - N_0(tmds_inter[7:0])
                    dc_balancing_next <= dc_balancing_reg - ones_in_tmds_inter + zeros_in_tmds_inter + to_integer(unsigned(tmds_intermediate(8 downto 7) and "10"));
                else
                    -- q_out[9] = 0
                    -- q_out[8] = tmds_inter[8]
                    -- q_out[7:0] = tmds_inter[7:0]
                    tmds_output_next <= '0' & tmds_intermediate(8) & tmds_intermediate(7 downto 0);
                    -- Track the amount of ones and zeros
                    -- Cnt(t) = Cnt(t-1) + 2*(~tmds_inter[8]) + N_0(tmds_inter[7:0]) - N_1(tmds_inter[7:0])
                    dc_balancing_next <= dc_balancing_reg + ones_in_tmds_inter - zeros_in_tmds_inter - to_integer(unsigned((not tmds_intermediate(8 downto 7)) and "10"));
                end if;
            end if;
        end if;

    end process NSL;

end architecture;