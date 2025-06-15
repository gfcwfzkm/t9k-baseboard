//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.02 
//Created Time: 2025-06-09 13:38:47
create_clock -name clk_27mhz -period 37.037 -waveform {0 18.518} [get_ports {clk_27mhz}] -add
create_generated_clock -name clk_tmds -source [get_ports {clk_27mhz}] -master_clock clk_27mhz -divide_by 4 -multiply_by 55 -add [get_nets {clk_tmds}]
create_generated_clock -name clk_video -source [get_nets {clk_tmds}] -master_clock clk_tmds -divide_by 5 -add [get_nets {clk_video}]
