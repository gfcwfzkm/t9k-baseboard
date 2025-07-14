import argparse

class OvertureDisassembler:
    REG_NAMES = ["R0", "R1", "R2", "R3", "R4", "R5", "R6", "IO"]
    ALU_OPS = {
        0: "OR",
        1: "NAND",
        2: "NOR",
        3: "AND",
        4: "ADD",
        5: "SUB",
        6: "XOR",
        7: "SHIFT"
    }
    JUMP_CONDITIONS = {
        0: "NOP",
        1: "JZ",
        2: "JLZ",
        3: "JLEZ",
        4: "JMP",
        5: "JNZ",
        6: "JGEZ",
        7: "JGZ"
    }

    def __init__(self, use_io_pseudo=False, ldi_hex=False, alu_no_op=False):
        self.use_io_pseudo = use_io_pseudo
        self.ldi_hex = ldi_hex
        self.alu_no_op = alu_no_op

    def disassemble_byte(self, byte):
        opcode = byte >> 6
        if opcode == 0:  # Load Immediate
            imm = byte & 0x3F
            if self.ldi_hex:
                return f"LDI #{imm:02X}"
            return f"LDI {imm}"
        elif opcode == 1:  # ALU or undefined
            if (byte >> 3) == 0b01000:  # ALU instruction
                alu_op = byte & 0x07
                op_name = self.ALU_OPS.get(alu_op, '?')
                return op_name if self.alu_no_op else f"OP {op_name}"
            return "HLT"
        elif opcode == 2:  # Copy
            src_reg = (byte >> 3) & 0x07
            dst_reg = byte & 0x07
            
            if self.use_io_pseudo:
                return f"MOV {self.REG_NAMES[dst_reg]}, {self.REG_NAMES[src_reg]}"
            else:
                if src_reg == 7 and dst_reg != 7:
                    return f"IN {self.REG_NAMES[dst_reg]}"
                elif dst_reg == 7 and src_reg != 7:
                    return f"OUT {self.REG_NAMES[src_reg]}"
                return f"MOV {self.REG_NAMES[dst_reg]}, {self.REG_NAMES[src_reg]}"
        elif opcode == 3:  # Jump or undefined
            if (byte >> 3) == 0b11000:  # Jump instruction
                cond = byte & 0x07
                return self.JUMP_CONDITIONS.get(cond, "HLT")
            return "HLT"
        return "HLT"

    def disassemble(self, byte_list):
        result = []
        for addr, byte in enumerate(byte_list):
            mnemonic = self.disassemble_byte(byte)
            result.append((addr, byte, mnemonic))
        return result

def read_binary_file(file_path):
    with open(file_path, 'rb') as f:
        return list(f.read())

def read_hex_text_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read().strip()
    content = ''.join(filter(str.isalnum, content)).upper()
    if not all(c in '0123456789ABCDEF' for c in content):
        raise ValueError("File contains non-hexadecimal characters")
    if len(content) % 2 != 0:
        raise ValueError("Hex string must have even length")
    return [int(content[i:i+2], 16) for i in range(0, len(content), 2)]

def main():
    parser = argparse.ArgumentParser(description='Disassembler for Overture CPU')
    parser.add_argument('input_file', help='Input file (binary or hex text)')
    parser.add_argument('--hex', action='store_true', help='Treat input as hex text file')
    parser.add_argument('--output', help='Output file (default: stdout)')
    parser.add_argument('--io-pseudo', action='store_true', 
                        help='Treat IO as MOV pseudo-register instead of IN/OUT')
    parser.add_argument('--ldi-hex', action='store_true', 
                        help='Display LDI immediates in hex format (with # prefix)')
    parser.add_argument('--alu-no-op', action='store_true', 
                        help='Remove OP prefix from ALU instructions')
    args = parser.parse_args()

    try:
        byte_list = read_hex_text_file(args.input_file) if args.hex else read_binary_file(args.input_file)
    except Exception as e:
        print(f"Error reading file: {e}")
        return

    disassembler = OvertureDisassembler(
        use_io_pseudo=args.io_pseudo, 
        ldi_hex=args.ldi_hex,
        alu_no_op=args.alu_no_op
    )
    disassembly = disassembler.disassemble(byte_list)

    output_lines = [f"{addr:04X}:   {byte:02X}    {mnemonic}" for addr, byte, mnemonic in disassembly]
    output_text = '\n'.join(output_lines)
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output_text)
    else:
        print(output_text)

if __name__ == '__main__':
    main()