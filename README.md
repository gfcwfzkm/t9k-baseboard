# t9k-baseboard
Tang Nano 9k Baseboard for Tang Nano 9k FPGA Board.

![3D Render](images/3drender_3.png)

## Introduction

The main idea is to have a baseboard for the Tang Nano 9k FPGA Board that allows to use it in a more comfortable way.
The baseboard will feature four PMOD connectors, a rotary encoder, a navigation switch and a WS2813-Style 8mm RGB LED.

The target goal of this project is to give students and hobbyists a platform to learn and experiment with FPGA technology in a more comfortable and cheap way. This project received support from the [Bern University of Applied Sciences (BFH)](https://www.bfh.ch/ti/en/). Thank you!

With cost being a main target, the Sipeed Tang Nano 9k FPGA Board was chosen as the base for this project. The board is available for around 14$ and features a Gowin GW1NR-9C with 8640 LUT4. The board is also equipped with a 32Mbit SPI Flash, a 27 MHz clock and a USB-C connector for programming and power.

The baseboard has been designed to be used with either a vanilla Tang Nano 9k Board, or one with the 1.13" SPI Display attached.
While the bigger, parallel RGB displays can still be used, the user will have a lot less PMODs available without conflicts to the display.

## Files
In the `kicad` folder, you will find the KiCad project files for the baseboard.
The project has been designed using KiCad 8.

In the `docs` folder, you will find the [BOM](docs/BOM.pdf) of this project for 10 PCBs, a [PDF schematic](docs/SCHEMA.pdf) of the board and a [Pinmap Table](docs/Pinmap.pdf) to help you assign the various I/Os in code.

## Getting Started
If you haven't gotten the board and the components yet, check out the [BOM](docs/BOM.pdf) to see what you need.

The board has been designed to be hand-assembled, so all you need is a fine soldering iron, tweezers and some solder.

On the software side, you can either use the open source YOSYS toolchain or the official Gowin tools. The board has been tested with the Gowin tools, so you might want to start with those. Sipeed has an guide on how to setup the IDE [here](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-Doc/install-the-ide.html).