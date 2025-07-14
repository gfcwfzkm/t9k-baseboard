import argparse
import re

class OvertureAssembler:
    # Available registers to move from/to
    REG_NAMES = ["R0", "R1", "R2", "R3", "R4", "R5", "R6", "IO"]
    # Available ALU operations. It uses R1 and R2, storing the result in R3.
    # Basically: R3 <= R1 ALUOP R2
    ALU_OPS = {
        "OR": 0, "NAND": 1, "NOR": 2, "AND": 3,
        "ADD": 4, "SUB": 5, "XOR": 6, "SHIFT": 7
    }
    # Jump instructions. If jump condition is true, it jumps to the address in R0
    JUMP_CONDITIONS = {
        "NOP" : 0,  # Never Branch - basically NOP
        "JZ"  : 1,  # Jump if R3 is zero
        "JLZ" : 2,  # Jump if R3 is less than zero
        "JLEZ": 3,  # Jump if R3 is less than or equal zero
        "JMP" : 4,  # Jump (always)
        "JNZ" : 5,  # Jump if R3 is not zero
        "JGEZ": 6,  # Jump if R3 is greater than or equal zero
        "JGZ" : 7   # Jump if R3 is greater than zero
    }
    # Special directives supported by the assembler
    DIRECTIVES = {
        "EQU",      # Assign a name an constant value: COUNTER EQU 10 or COUNTER = 10
        "MACRO",    # Start of an custom macro: %MACRO LJNZ ADDRESS
        "ENDMACRO", # End of an custom macro: %ENDMACRO
        "ORG"       # Set the internal program address: ORG 0x30
    }
    
    def __init__(self, alu_no_op=False):
        self.alu_no_op = alu_no_op
        self.labels = {}
        self.constants = {}
        self.macros = {}
        self.current_address = 0
        self.macro_mode = False
        self.current_macro = None
        self.instructions = []
        self.output = []
        self.expanded_lines = []
        
    def reset_assembler(self):
        self.labels = {}
        self.constants = {}
        self.macros = {}
        self.current_address = 0
        self.macro_mode = False
        self.current_macro = None
        self.instructions = []
        self.output = []
        self.expanded_lines = []
    
    def parse_line(self, line):
        # Remove comments and clean line
        line = re.sub(r';.*', '', line).strip()
        if not line:
            return []
        
        # Tokenize the line
        tokens = []
        current = ''
        in_quotes = False
        for char in line:
            if char == '"':
                in_quotes = not in_quotes
                current += char
            elif char in [' ', ',', '\t'] and not in_quotes:
                if current:
                    tokens.append(current)
                    current = ''
            else:
                current += char
        if current:
            tokens.append(current)
        
        return tokens
    
    def handle_directive(self, tokens):
        if not tokens:
            return False
            
        # Handle constant definitions with = operator
        if len(tokens) >= 3 and tokens[1] == '=':
            name = tokens[0]
            value_str = ''.join(tokens[2:])
            value = self.parse_value(value_str)
            self.constants[name] = value
            return True
            
        # Handle EQU directive
        if len(tokens) >= 3 and tokens[1].upper() == 'EQU':
            name = tokens[0]
            value_str = ''.join(tokens[2:])
            value = self.parse_value(value_str)
            self.constants[name] = value
            return True
            
        directive = tokens[0].upper()
        
        if directive == "EQU" and len(tokens) >= 3:
            name = tokens[1]
            value_str = ''.join(tokens[2:])
            value = self.parse_value(value_str)
            self.constants[name] = value
            return True
        
        elif directive == "%MACRO":
            if self.macro_mode:
                raise ValueError("Nested macros are not supported")
            if len(tokens) < 2:
                raise ValueError("Macro name required")
            self.macro_mode = True
            self.current_macro = {
                'name': tokens[1],
                'params': tokens[2:],
                'body': []
            }
            return True
        
        elif directive == "%ENDMACRO":
            if not self.macro_mode:
                raise ValueError("ENDMACRO without MACRO")
            self.macros[self.current_macro['name']] = self.current_macro
            self.macro_mode = False
            self.current_macro = None
            return True
        
        elif directive == "ORG":
            if len(tokens) < 2:
                raise ValueError("ORG requires an address")
            self.current_address = self.parse_value(tokens[1])
            return True
        
        return False
    
    def expand_macro(self, macro_name, args):
        if macro_name not in self.macros:
            raise ValueError(f"Undefined macro: {macro_name}")
        
        macro = self.macros[macro_name]
        if len(args) != len(macro['params']):
            raise ValueError(f"Macro {macro_name} expects {len(macro['params'])} arguments")
        
        param_map = dict(zip(macro['params'], args))
        expanded = []
        
        for line in macro['body']:
            expanded_line = []
            for token in line:
                if token in param_map:
                    expanded_line.append(param_map[token])
                else:
                    expanded_line.append(token)
            expanded.append(expanded_line)
        
        return expanded
    
    def parse_value(self, value_str):
        # Try to resolve as constant
        if value_str in self.constants:
            return self.constants[value_str]
        
        # Try to resolve as label
        if value_str in self.labels:
            return self.labels[value_str]
        
        # Parse numeric values
        try:
            if value_str.startswith('#'):
                return int(value_str[1:], 16)
            elif value_str.startswith('0x'):
                return int(value_str[2:], 16)
            elif value_str.startswith('0b'):
                return int(value_str[2:], 2)
            else:
                return int(value_str)
        except ValueError:
            # Return as string for later resolution
            return value_str
    
    def encode_instruction(self, tokens):
        if not tokens:
            return None
        
        mnemonic = tokens[0].upper()
        operands = tokens[1:]
        
        # Handle ALU operations without...
        if mnemonic in self.ALU_OPS:
            # Encode as ALU instruction
            alu_op = self.ALU_OPS[mnemonic]
            return 0b01000000 | alu_op
        # ... or with OP prefix. I couldn't decide which one I like more.
        elif mnemonic == "OP" and operands:
            alu_op_name = operands[0].upper()
            if alu_op_name not in self.ALU_OPS:
                raise ValueError(f"Invalid ALU operation: {alu_op_name}")
            alu_op = self.ALU_OPS[alu_op_name]
            return 0b01000000 | alu_op
        
        # Handle LDI
        elif mnemonic == "LDI" and operands:
            value = self.parse_value(operands[0])
            if isinstance(value, str):
                # Unresolved symbol, handle in second pass
                return value
            if value < 0 or value > 0x3F:
                raise ValueError(f"LDI value out of range: {value} (0-63)")
            return value  # Top bits are 00
        
        # Handle copy operations
        elif mnemonic == "MOV" and len(operands) == 2:
            dst = operands[0].upper()
            src = operands[1].upper()
            
            # Validate registers
            if dst not in self.REG_NAMES or src not in self.REG_NAMES:
                raise ValueError(f"Invalid register name: {dst} or {src}")
            
            dst_idx = self.REG_NAMES.index(dst)
            src_idx = self.REG_NAMES.index(src)
            
            return 0b10000000 | (src_idx << 3) | dst_idx
        
        # Handle explicit IN/OUT
        elif mnemonic == "IN" and operands:
            dst = operands[0].upper()
            if dst not in self.REG_NAMES:
                raise ValueError(f"Invalid register name: {dst}")
            dst_idx = self.REG_NAMES.index(dst)
            return 0b10000000 | (7 << 3) | dst_idx
        
        elif mnemonic == "OUT" and operands:
            src = operands[0].upper()
            if src not in self.REG_NAMES:
                raise ValueError(f"Invalid register name: {src}")
            src_idx = self.REG_NAMES.index(src)
            return 0b10000000 | (src_idx << 3) | 7
        
        # Handle jump instructions
        elif mnemonic in self.JUMP_CONDITIONS:
            if operands:
                raise ValueError(f'{mnemonic} {operands[0]} not supported - Use LDI {operands[0]} before {mnemonic}')
            condition = self.JUMP_CONDITIONS[mnemonic]
            return 0b11000000 | condition
        
        # Handle HLT
        elif mnemonic == "HLT":
            return 0xFF
        
        raise ValueError(f"Unrecognized instruction: {mnemonic} {' '.join(operands)}")
    
    def first_pass(self, lines):
        """First pass to collect labels, constants, and macros."""
        self.reset_assembler()
        line_num = 0
        
        for line in lines:
            line_num += 1
            try:
                # Skip empty lines
                clean_line = line.strip()
                if not clean_line or clean_line.startswith(';'):
                    continue
                    
                tokens = self.parse_line(line)
                if not tokens:
                    continue
                
                # Handle labels - both "label:" and "label :" formats
                if tokens[0].endswith(':'):
                    # "label:" format
                    label = tokens[0][:-1]
                    tokens = tokens[1:]
                elif len(tokens) > 1 and tokens[1] == ':':
                    # "label :" format
                    label = tokens[0]
                    tokens = tokens[2:]
                else:
                    label = None
                    
                # Record label if found
                if label:
                    if label in self.labels:
                        raise ValueError(f"Duplicate label: {label}")
                    self.labels[label] = self.current_address
                    
                # Skip line if only label present
                if not tokens:
                    continue
                
                # Handle constant definitions and directives
                if self.handle_directive(tokens):
                    continue
                
                # Handle macro definition
                if self.macro_mode:
                    if tokens[0].upper() == "%ENDMACRO":
                        self.handle_directive(tokens)
                    else:
                        self.current_macro['body'].append(tokens)
                    continue
                
                # Handle macro invocation
                if tokens[0] in self.macros:
                    expanded = self.expand_macro(tokens[0], tokens[1:])
                    for expanded_line in expanded:
                        self.expanded_lines.append(expanded_line)
                        self.instructions.append((self.current_address, expanded_line))
                        self.current_address += 1
                    continue
                
                # Handle regular instructions
                self.expanded_lines.append(tokens)
                self.instructions.append((self.current_address, tokens))
                self.current_address += 1
                
            except Exception as e:
                raise ValueError(f"Line {line_num}: {str(e)} - {line}")
    
    def second_pass(self):
        """Second pass to resolve labels and constants, and encode instructions."""
        for address, tokens in self.instructions:
            try:
                # Resolve constants and labels in operands
                resolved_tokens = []
                for token in tokens:
                    # Skip label definitions
                    if token.endswith(':'):
                        continue
                    if token in self.constants:
                        resolved_tokens.append(str(self.constants[token]))
                    elif token in self.labels:
                        resolved_tokens.append(str(self.labels[token]))
                    else:
                        resolved_tokens.append(token)
                
                # Encode instruction
                instruction = self.encode_instruction(resolved_tokens)
                
                # If we got a string back, it's an unresolved symbol
                if isinstance(instruction, str):
                    # Try to resolve it now
                    if instruction in self.labels:
                        instruction = self.labels[instruction]
                    elif instruction in self.constants:
                        instruction = self.constants[instruction]
                    else:
                        raise ValueError(f"Unresolved symbol: {instruction}")
                
                self.output.append(instruction)
            except Exception as e:
                raise ValueError(f"Address {address:04X}: {str(e)} - {' '.join(tokens)}")
    
    def assemble(self, source_lines):
        self.first_pass(source_lines)
        self.second_pass()
        return self.output
    
    def write_output(self, output_format, output_file=None):
        output_text = ""
        
        if output_format == "binary":
            binary_data = bytes(self.output)
            if output_file:
                with open(output_file, 'wb') as f:
                    f.write(binary_data)
            else:
                output_text = binary_data.hex().upper()
        
        elif output_format == "hex":
            hex_str = ''.join(f"{b:02X}" for b in self.output)
            if output_file:
                with open(output_file, 'w') as f:
                    f.write(hex_str)
            else:
                output_text = hex_str
        
        elif output_format == "dump":
            lines = []
            for i, byte in enumerate(self.output):
                address = self.instructions[i][0]
                tokens = self.instructions[i][1]
                mnemonic = ' '.join(tokens)
                lines.append(f"{address:04X}:   {byte:02X}    {mnemonic}")
            output_text = '\n'.join(lines)
            if output_file:
                with open(output_file, 'w') as f:
                    f.write(output_text)
            
        elif output_format == "vhdl":
            lines = []
            for i, byte in enumerate(self.output):
                address = self.instructions[i][0]
                tokens = self.instructions[i][1]
                mnemonic = ' '.join(tokens)
                lines.append(f'x"{byte:02X}",  -- {address:04X}: {mnemonic}')
            output_text = '\n'.join(lines)
            if output_file:
                with open(output_file, 'w') as f:
                    f.write(output_text)
        
        if not output_file and output_text:
            print(output_text)

def main():
    parser = argparse.ArgumentParser(description='Assembler for Overture CPU')
    parser.add_argument('input_file', help='Input assembly file')
    parser.add_argument('--output', help='Output file (default: stdout)')
    parser.add_argument('--format', choices=['binary', 'hex', 'dump', 'vhdl'], 
                        default='hex', help='Output format')
    args = parser.parse_args()

    try:
        # Read input file
        with open(args.input_file, 'r') as f:
            source_lines = f.readlines()
        
        # Create and configure assembler
        assembler = OvertureAssembler(
            alu_no_op=True
        )
        
        # Assemble program
        assembler.assemble(source_lines)
        
        # Write output
        assembler.write_output(args.format, args.output)
    
    except Exception as e:
        print(f"Assembly error: {str(e)}")
        exit(1)

if __name__ == '__main__':
    main()