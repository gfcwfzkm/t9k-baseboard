--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.10.02
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9
--Device Version: C
--Created Time: Sun Jun  8 12:50:28 2025

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_CLKDIV
    port (
        clkout: out std_logic;
        hclkin: in std_logic;
        resetn: in std_logic
    );
end component;

your_instance_name: Gowin_CLKDIV
    port map (
        clkout => clkout,
        hclkin => hclkin,
        resetn => resetn
    );

----------Copy end-------------------
