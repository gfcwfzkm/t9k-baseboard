-- TEROSHDL Documentation:
--! @title Tang Nano 9K HDMI Demo Top
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 15.06.2025
--! @brief Demo to render a simple 720p HDMI video output on the Tang Nano 9K board
--!
--! This is a simple demo to render a 720p HDMI video output on the Tang Nano 9K board.
--! It uses a video clock of 74.25 MHz, which is 5x the TMDS clock speed of 371.25 MHz.
--!
--! While the video generator is identical to the ones used for VGA, the trick here is
--! to convert the video signals to TMDS signals, which are then serialized
--! and output as differential signals.
--!
--! Check the other files in this directory for the video generator and the TMDS
--! encoder.
--!

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity top is
    port (
        --! 27 MHz clock input of the Tang Nano 9K board
        clk_27mhz  : in  std_logic;
        --! Reset button, active LOW
        btn_s1     : in  std_logic;

        --! Differential TMDS clock output negative
        tmds_clk_n : out std_logic;
        --! Differential TMDS clock output positive
        tmds_clk_p : out std_logic;
        --! Differential TMDS data output negative, 3 channels
        tmds_d_n   : out std_logic_vector(2 downto 0);
        --! Differential TMDS data output positive, 3 channels
        tmds_d_p   : out std_logic_vector(2 downto 0)
    );
end top;

architecture RTL of top is

    -- Output LVDS buffer driver
    component ELVDS_OBUF
        port (
            O  : out std_logic;
            OB : out std_logic;
            I  : in  std_logic
        );
    end component;

    -- PLL to get the 5x video_clock_speed 
    component Gowin_rPLL
        port (
            clkout : out std_logic;
            lock   : out std_logic;
            clkin  : in std_logic
        );
    end component;

    -- Clockdiv, configured to divide by 5
    component Gowin_CLKDIV
        port (
            clkout : out std_logic;
            hclkin : in std_logic;
            resetn : in std_logic	-- ACTIVE LOW
        );
    end component;
    -- Serializer for 10 bits
    component OSER10
        generic(
            GSREN : string := "false";
            LSREN : string := "true");
        port (
            Q     : out std_logic;
            D0    : in  std_logic;
            D1    : in  std_logic;
            D2    : in  std_logic;
            D3    : in  std_logic;
            D4    : in  std_logic;
            D5    : in  std_logic;
            D6    : in  std_logic;
            D7    : in  std_logic;
            D8    : in  std_logic;
            D9    : in  std_logic;
            FCLK  : in std_logic;   -- "Fast Clock"?
            PCLK  : in std_logic;   -- "Pixel Clock"?
            RESET : in std_logic    -- ACTIVE-HIGH
        );
    end component;
    -- Note: I love how Gowin IPs can't decide if they want active-high
    -- or active low resets.

    --! Reset Counter Register to debounce the reset button
    signal rst_counter_reg : unsigned(4 downto 0);
    --! TOP value of the reset counter
    constant RST_CNT_TOP   : unsigned(rst_counter_reg'high downto 0) := (others => '1');
    --! Reset signal, active HIGH
    signal reset       	   : std_logic;
    --! PLL output lock signal, active HIGH
    signal pll_lock        : std_logic;

    --! PLL clock, 5x video clock speed (371.25 MHz)
    signal clk_tmds  : std_logic;
    --! Video clock, from a x5 clock divider on clk_tmds
    signal clk_video : std_logic;

    --! Serialized TMDS clock channel
    signal tmds_clk : std_logic;
    --! Serialized TMDS data / color channels
    signal tmds_d : std_logic_vector(2 downto 0); 

    --! Parallel TMDS signals
    signal red_tmds_par, green_tmds_par, blue_tmds_par : std_logic_vector(9 downto 0);

    --! Video color signals, 8 bits each
    signal red, green, blue : std_logic_vector(7 downto 0);
    --! Video control signals
    signal disp_en, hsync, vsync : std_logic;

begin

    -- If button pressed, reset it all. If released, increment counter
    -- until it reaches the TOP - when counter is at TOP and the PLL
    -- is locked, deassert the RESET signal.
    --! Reset counter to debounce the reset button
    RST_DEBOUNCE : process (clk_27mhz, btn_s1) begin
        if rising_edge(clk_27mhz) then
            if btn_s1 = '1' then -- BTN S1 pressed
                rst_counter_reg <= (others => '0');
            else
                if rst_counter_reg /= RST_CNT_TOP then
                    rst_counter_reg <= rst_counter_reg + 1;
                end if;
            end if;
        end if;
    end process RST_DEBOUNCE;

    --! Release the reset when the counter reaches the TOP value AND the PLL is locked
    reset <= (and rst_counter_reg) and pll_lock;
    
    -- Repurposed video test generator, only supports 3-bit colors, so only the MSB
    -- of the color signal vectors is set
    --! Video Test Image Generator
    VIDEOGEN : entity work.video
        port map (
            clk   => clk_video,
            reset => reset,
            r     => red(7),
            g     => green(7),
            b     => blue(7),
            hsync => hsync,
            vsync => vsync,
            de    => disp_en
    );

    -- Set the remaining bits of the color signal vectors to zero
    red(6 downto 0)   <= (others => red(7));
    green(6 downto 0) <= (others => green(7));
    blue(6 downto 0)  <= (others => blue(7));

    --! Encode the video red channel to a TMDS signal
    TMDS_RED : entity work.tmds_encoder
        port map (
            clk  => clk_video,
            reset => reset,
            disp_enable => disp_en,
            hsync => '0',
            vsync => '0',
            color_data  => red,
            tmds_encoded => red_tmds_par
    );
    --! Encode the video green channel to a TMDS signal
    TMDS_GREEN : entity work.tmds_encoder
        port map (
            clk  => clk_video,
            reset => reset,
            disp_enable   => disp_en,
            hsync => '0',
            vsync => '0',
            color_data  => green,
            tmds_encoded => green_tmds_par
    );
    --! Encode the video blue channel, H/VSYNC and ENABLE signals to a TMDS signal
    TMDS_BLUE : entity work.tmds_encoder
        port map (
            clk  => clk_video,
            reset => reset,
            disp_enable   => disp_en,
            hsync => hsync,
            vsync => vsync,
            color_data  => blue,
            tmds_encoded => blue_tmds_par
    );

    -------------- Serialize the 10 bit raw/parallel TMDS signals --------------
    --! Serializer for the red TMDS channel
    SERIALIZE_RED : OSER10
        generic map (
            GSREN => "false",
            LSREN => "true"
        )
        port map (
            Q     => tmds_d(2),
            D0    => red_tmds_par(0),
            D1    => red_tmds_par(1),
            D2    => red_tmds_par(2),
            D3    => red_tmds_par(3),
            D4    => red_tmds_par(4),
            D5    => red_tmds_par(5),
            D6    => red_tmds_par(6),
            D7    => red_tmds_par(7),
            D8    => red_tmds_par(8),
            D9    => red_tmds_par(9),
            FCLK  => clk_tmds,
            PCLK  => clk_video,
            RESET => reset
    );
    --! Serializer for the green TMDS channel
    SERIALIZE_GREEN : OSER10
        generic map (
            GSREN => "false",
            LSREN => "true"
        )
        port map (
            Q     => tmds_d(1),
            D0    => green_tmds_par(0),
            D1    => green_tmds_par(1),
            D2    => green_tmds_par(2),
            D3    => green_tmds_par(3),
            D4    => green_tmds_par(4),
            D5    => green_tmds_par(5),
            D6    => green_tmds_par(6),
            D7    => green_tmds_par(7),
            D8    => green_tmds_par(8),
            D9    => green_tmds_par(9),
            FCLK  => clk_tmds,
            PCLK  => clk_video,
            RESET => reset
    );
    --! Serializer for the blue TMDS channel
    SERIALIZE_BLUE : OSER10
        generic map (
            GSREN => "false",
            LSREN => "true"
        )
        port map (
            Q     => tmds_d(0),
            D0    => blue_tmds_par(0),
            D1    => blue_tmds_par(1),
            D2    => blue_tmds_par(2),
            D3    => blue_tmds_par(3),
            D4    => blue_tmds_par(4),
            D5    => blue_tmds_par(5),
            D6    => blue_tmds_par(6),
            D7    => blue_tmds_par(7),
            D8    => blue_tmds_par(8),
            D9    => blue_tmds_par(9),
            FCLK  => clk_tmds,
            PCLK  => clk_video,
            RESET => reset
    );
    --! Serializer for the TMDS clock channel
    SERIALIZE_CLOCK : OSER10
        generic map (
            GSREN => "false",
            LSREN => "true"
        )
        port map (
            Q     => tmds_clk,
            D0    => '1',
            D1    => '1',
            D2    => '1',
            D3    => '1',
            D4    => '1',
            D5    => '0',
            D6    => '0',
            D7    => '0',
            D8    => '0',
            D9    => '0',
            FCLK  => clk_tmds,
            PCLK  => clk_video,
            RESET => reset
    );

    ----------------------------- Clock Generation -----------------------------
    -- Clock PLL, to get the 720p TMDS clock (5 x 74.25 MHz)
    -- It is actually generating 371.2 MHz instead of 371.25 MHz
    --! Clock PLL to get the 371.25 MHz TMDS clock
    CLKPLL_371MHZ: Gowin_rPLL
        port map (
            clkout => clk_tmds,
            clkin  => clk_27mhz
    );
    -- Clock divider to get the actual pixel clock of 74.25 MHz
    -- Will actually be 74.24 MHz - good enough
    --! Clock divider to get 74.25 MHz pixel clock from 371.25 MHz TMDS clock
    CLKDIV_74MHz: Gowin_CLKDIV
        port map (
            clkout => clk_video,
            hclkin => clk_tmds,
            resetn => not reset
    );

    ----------------------------- Output Drivers -------------------------------
    --! LVDS output driver / buffer for the TMDS clock
    TMDS_CLK_OBUF : ELVDS_OBUF
        port map (
            O  => tmds_clk_p,
            OB => tmds_clk_n,
            I  => tmds_clk
    );
    --! LVDS output drivers / buffers for the TMDS blue data channel 
    TMDS_CH0_BL_OBUF : ELVDS_OBUF
        port map (
            O  => tmds_d_p(0),
            OB => tmds_d_n(0),
            I  => tmds_d(0)
    );
    --! LVDS output drivers / buffers for the TMDS green data channel
    TMDS_CH1_GR_OBUF : ELVDS_OBUF
        port map (
            O  => tmds_d_p(1),
            OB => tmds_d_n(1),
            I  => tmds_d(1)
    );
    --! LVDS output drivers / buffers for the TMDS red data channel
    TMDS_CH2_RD_OBUF : ELVDS_OBUF
        port map (
            O  => tmds_d_p(2),
            OB => tmds_d_n(2),
            I  => tmds_d(2)
    );

end architecture RTL;