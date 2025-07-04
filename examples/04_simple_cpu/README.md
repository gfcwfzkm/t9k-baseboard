# Simple 8-bit CPU Example

This example demonstrates and explains how to implement a simple 8-bit CPU using VHDL.
The CPU is a basic design and has limited functionality, but serves as a good starting point for demonstation purposes. The Overture computer architecture from the game [Turing Complete](https://turingcomplete.game/) will be implemented with some slight modifications / additions.

In contrast to the other examples, this will have a more theoretical, educational focus. But if you don't care about that, just run and load the project on your FPGA board and have fun with it!

## Chapters
1. [Introduction](#1-introduction)
2. [The Instruction Set Architecture](#2-the-instruction-set-architecture)
   - [2.1 🔴🔴🟤🟤🟤🟤🟤🟤 Load Immediate Instruction](#21-🔴🔴🟤🟤🟤🟤🟤🟤-load-immediate-instruction)
   - [2.2 🔴🟢🟤🟤🟤🟤🟤🟤 ALU/Compute Instruction](#22-🔴🟢🟤🟤🟤🟤🟤🟤-alu-compute-instruction)
   - [2.3 🟢🔴🟤🟤🟤🟤🟤🟤 Copy Instruction](#23-🟢🔴🟤🟤🟤🟤🟤🟤-copy-instruction)
   - [2.4 🟢🟢🟤🟤🟤🟤🟤🟤 Jump/Branch Instruction](#24-🟢🟥-jumpbranch-instruction)
   - [2.5 Undefined Instructions](#25-undefined-instructions)
3. [CPU Architecture](#3-cpu-architecture)
4. Fetch
5. Decode
6. Execute
7. Write Back
8. I/O Operations
9. Example Program
10. Conclusion

## [1. Introduction](#chapters)

While state machines are a powerful tool to implement more complex logic, they can be cumbersome if a general-purpose design is needed, that can be easily modified and changed. A CPU is a good example of such a design, as it is basically just one big state machine that can be programmed to do different things.

In this example, we will implement a simple 8-bit CPU that can execute a small set of instructions. The CPU will be able to perform basic arithmetic operations, load and store data, and control the flow of execution. The design will be modular and easy to understand, making it a good starting point for more complex designs.

It will be implemented as a single-cycle CPU, meaning that each instruction will be executed in a single clock cycle. While the execution speed is not very high, due to the long datapath, it is a good starting point for understanding how a CPU works. The design is structured in a way that allows to modify it to an multi-cycle or pipelined design later on, if desired.

In this example, we will implement the Overture computer architecture from the game [Turing Complete](https://turingcomplete.game/). The ISA will be extended with some additional instructions to make it more versatile and useful for general-purpose programming. This computer architecture has a 1-byte wide ISA and *originally* contains 6 registers, although we extend it to 7 registers (R0 to R7). Some of these registers are used for special purposes, such as for ALU operations or the address on a jump/branch instruction. The computer also contains an input/output port, which can be used to read from and write to external devices. While no RAM is implemented in this example, our modified computer architecture is modified to easily support a RAM module.

> Such a modified, faster or more compact design is left as an exercise for the reader.

## [2. The Instruction Set Architecture](#chapters)

To run general purpuse programs, a CPU needs to have an instruction set architecture (ISA) that defines the instructions it can execute. The ISA is a set of instructions that the CPU can understand and execute. A ISA should define instructions to perform basic arithmetic and logical operations, load and store data, and control the flow of execution. It should also have instructions to interact with memory and I/O devices, such as reading from and writing to memory or I/O ports.

All registers can be used as general-purpose registers, but some of them have special purposes. The CPU has 7 registers (R0 to R6), each 8 bits wide, which can be used to store data and addresses. The registers are used to hold the operands for the ALU operations, the result of the ALU operations, and the address for jump/branch instructions.
The following registers are used, with their special purpose defined:

- **R0**: Used to load immediate values and as jump/branch destination.
- **R1**: Used as first operand for ALU operations.
- **R2**: Used as second operand for ALU operations.
- **R3**: Used to store the result of ALU operations.
- **R4**: General-purpose register with no special purpose.
- **R5**: General-purpose register with no special purpose.
- **R6**: Used to store the address to the I/O device for input/output operations.

In general, the ISA consists of the four main instruction types:

- 🔴🔴🟤🟤🟤🟤🟤🟤 Load Immediate Instruction
- 🔴🟢🟤🟤🟤🟤🟤🟤 ALU/Compute Instruction
- 🟢🔴🟤🟤🟤🟤🟤🟤 Copy Instruction
- 🟢🟢🟤🟤🟤🟤🟤🟤 Jump/Branch Instruction

> Note:
>
> A green circle 🟢 stands for an set bit (bit = 1), a red circle 🔴 for an cleared bit (bit = 0) and brown circle 🟤 for an "don't care" or not further specified bit. The left-most circle stands for the most-significant bit, in this case, bit 7 while the right-most circle represents bit 0.

### [2.1 🔴🔴🟤🟤🟤🟤🟤🟤 Load Immediate Instruction](#2-the-instruction-set-architecture)

The Load Immediate instruction is used to load a constant value into a register. It loads an 6-bit immediate value (0 to 63) into the register zero (R0).

### [2.2 🔴🟢🟤🟤🟤🟤🟤🟤 ALU/Compute Instruction](#2-the-instruction-set-architecture)

The ALU/Compute instruction is used to perform arithmetic and logical operations. The register one (R1) and register two (R2) are used as input operands, while the result is stored in register three (R3). The instruction also specifies the operation to be performed:

- 🔴🟢🟤🟤🟤🔴🔴🔴 **OR**
  - Bitwise OR operation between R1 and R2, result in R3.
- 🔴🟢🟤🟤🟤🔴🔴🟢 **NAND**
  - Bitwise NAND operation between R1 and R2, result in R3.
- 🔴🟢🟤🟤🟤🔴🟢🔴 **NOR**
  - Bitwise NOR operation between R1 and R2, result in R3.
- 🔴🟢🟤🟤🟤🔴🟢🟢 **AND**
  - Bitwise AND operation between R1 and R2, result in R3.
- 🔴🟢🟤🟤🟤🟢🔴🔴 **ADD**
  - Addition of R1 and R2, result in R3 (No carry / overflow detection).
- 🔴🟢🟤🟤🟤🟢🔴🟢 **SUB**
  - Subtraction of R2 from R1, result in R3 (No borrow / overflow detection).
- 🔴🟢🟤🟤🟤🟢🟢🔴 **SHIFT**
  - Shift R1 to the left (R2 > 0) or right (R2 < 0) by the value in R2, result in R3. If R2 is 0, R1 is copied to R3.
- 🔴🟢🟤🟤🟤🟢🟢🟢 **XOR**
  - Bitwise XOR operation between R1 and R2, result in R3.

### [2.3 🟢🔴🟤🟤🟤🟤🟤🟤 Copy Instruction](#2-the-instruction-set-architecture)

The Copy instruction is used to copy the value of one register to another register. The instruction specifies the source register (bits 3 to 5, yellow) and the destination register (bits 0 to 2, blue) 🟢🔴🟡🟡🟡🔵🔵🔵.

The following destination / sources are specified:

- 🔴🔴🔴 **R0**
  - Also used to load immediate values and as jump/branch destination.
- 🔴🔴🟢 **R1**
  - Also used as first operand for ALU operations.
- 🔴🟢🔴 **R2**
  - Also used as second operand for ALU operations.
- 🔴🟢🟢 **R3**
  - Also used to store the result of ALU operations.
- 🟢🔴🔴 **R4**
  - General-purpose register with no special purpose.
- 🟢🔴🟢 **R5**
  - General-purpose register with no special purpose.
- 🟢🟢🔴 **R6**
  - Used to store the address to the I/O device for input/output operations.
- 🟢🟢🟢 **INPUT / OUTPUT**
  - Used to read from or write to the I/O device port. The register R6 can be used to specify the address of the I/O device, if multiple devices are connected.


### [2.4 🟢🟢🟤🟤🟤🟤🟤🟤 Jump/Branch Instruction](#2-the-instruction-set-architecture)

The Jump/Branch instruction is used to control the flow of execution. It can be used to jump to a specific address or to branch to a different instruction based on a condition. The instruction does not specify the address to jump to, but instead uses the value in register zero (R0) as the address to jump to. Instead, it specifies the condition to branch on, which is determined by the value in register three (R3).

The following conditions are specified:
- 🟢🟢🟤🟤🟤🔴🔴🔴 **Never branches**
- 🟢🟢🟤🟤🟤🔴🔴🟢 **R3 equals 0**
- 🟢🟢🟤🟤🟤🔴🟢🔴 **R3 less than 0**
- 🟢🟢🟤🟤🟤🔴🟢🟢 **R3 less than or equals 0**
- 🟢🟢🟤🟤🟤🟢🔴🔴 **Always jump**
- 🟢🟢🟤🟤🟤🟢🔴🟢 **R3 not equal zero**
- 🟢🟢🟤🟤🟤🟢🟢🔴 **R3 greater than equals zero**
- 🟢🟢🟤🟤🟤🟢🟢🟢 **R3 greater than 0**

## [2.5 Undefined Instructions](#2-the-instruction-set-architecture)

Some keen readers might have noticed that the instruction set architecture does not define all possible instructions.The game simply never specified what the other instructions should do, so they are left undefined.

If the CPU encounters an undefined instruction, it will simply **halt execution** and do nothing, forcing a reset of the CPU and thus preventing unexpected behavior.

## [3. CPU Architecture](#chapters)

The CPU architecture is a single-cycle design, meaning that each instruction is executed in a single clock cycle. We also need to define the inputs and outputs of the CPU, the internal components, and the connections between them.

The CPU has the following inputs and outputs:
- **Inputs:**
  - `clk`: The clock signal, used to synchronize the CPU.
  - `reset`: The active-high reset signal, used to reset the CPU.
  - `instruction`: The instruction to be executed, provided by the instruction memory.
  - `io_in`: The input data from the I/O device, if any.
- **Outputs:**
  - `instruction_addr`: The address of the instruction to be executed, used to fetch the instruction from the instruction memory.
  - `io_addr`: The address of the I/O device, if any.
  - `io_out`: The output data to the I/O device, if any.
  - `io_write_enable`: The write enable signal for the I/O device, if any.

The CPU's memory is placed externally, allowing to easily change the program that is executed. The CPU will fetch the instruction from the instruction memory, decode it, execute it, and write back the result to the registers or the I/O device.