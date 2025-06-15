"""
Theory-Checking TMDS

Just a basic script where I lay out the TMDS flowchart
in python code, to see if I'm understanding and applying
it correctly. Includes an TMDS encoder and decoder.

The test is performed using a stimuli CSV pulled from the waveform
file from https://fpga.mit.edu/6205/F24/assignments/hdmi/tmds_ds

Both the DVI 1.0 specs document and the HDMI 1.3 specs document were used,
but only the DVI video part was implemented.
"""
import csv

def prettyPrintBinary(input: int, bits=8) -> str:
	"""
	Formats an integer as a binary string, grouping bits in sets of 4.
	Arguments:
	    input (int): The integer value to format.
		bits (int): The number of bits to represent the integer.
	Returns:
		str: A string representation of the integer in binary, grouped in sets of 4 bits.
	"""
	# Ugly-ass function to format binary strings in groups of 4 bits
	bin_str = f"{input:0{bits}b}"
	first_group_size = len(bin_str) % 4
	if first_group_size == 0:
		first_group_size = 4
	groups = [bin_str[:first_group_size]]
	for i in range(first_group_size, len(bin_str), 4):
		groups.append(bin_str[i:i+4])
	return ' '.join(groups)

def getBit(input : int, bitpos : int) -> int:
	"""
	Extracts the value of a specific bit from an integer.
	Arguments:
		input (int): The integer value from which to extract the bit.
		bitpos (int): The position of the bit to extract (0 for least significant bit).
	Returns:
		int: The value of the bit at the specified position (0 or 1).
	"""
	return (input & (1 << bitpos)) >> bitpos

def invBit(input : int) -> int:
	"""Inverts a bit"""
	return 0 if input else 1

def CountOnesInData(input : int, bits = 8) -> int:
	"""
	Count the set bits in the input integer
	Arguments:
		input (int): Integer value to count the bits in.
		bits (int): Number of bits to consider in the input.
	Returns:
		int: The count of set bits (1s) in the input integer.
	"""
	ones = 0
	for n in range(bits):
		if (input & (1 << n)):
			ones += 1
	return ones

def CountZerosInData(input : int) -> int:
	"""Get the number of zeros in the input data, only for 8-bit inputs!"""
	return 8 - CountOnesInData(input)

class TMDS:
	"""
	A class to encode and decode TMDS (Transition Minimized Differential Signaling)
	"""

	def __init__(self):
		self.encode_cnt = 0

	def Encode(self, input : int, DE : bool = True,  ctrl : int = 0) -> int:
		if input > 255:
			raise ValueError("Value exceeds 255, thus is not 8-bit!")
		if input < 0:
			raise ValueError("Give me unsigned integers only!")
		if ctrl > 3:
			raise ValueError("")
		# First part of TMDS is transition-minimizing.
		# For this, count the ones in the input. If it exceeds 4 or is equal
		# to 4 with the LSB=0, then XOR things, otherwise XNOR it.
		ones_in_data = CountOnesInData(input)

		# XORing/XNORing is as follows:
		# q_out[0] = input[0]
		q_m = input & (1 << 0)
		use_xnor = True if (ones_in_data > 4) or ((ones_in_data == 4) and not (input & (1 << 0))) else False

		# q_out[n] = q_out[n-1] XOR/XNOR input[1]		
		for n in range(1, 8):
			# Bit is either 0 or 1, based on the logical operation
			bit = getBit(q_m, n-1) ^ getBit(input, n)
			if use_xnor:
				bit = 0 if bit else 1 # XNOR 
			q_m |= (bit << n)       
		
		# 9th bit determines if we used XOR or XNOR, so attach that to q_out
		q_m |= 0 if use_xnor else (1 << 8)

		q_out = 0
		# if DE is high, send C1/C0 instead!
		# I don't get it, DVI 1.0 spec lists
		# different values for C1/C0 than the HDMI 1.3 spec, that I found.
		# Since other implementations use the HDMI 1.3 spec, I will too.
		if not DE:
			# "Upon entering a Video Data Period, the data stream disparity (encode_cnt)
			#  shall be considered zero by the encoder"
			# Basically, reset it during the control period.
			self.encode_cnt = 0
			if ctrl == 0:
				q_out = 0b1101010100
				return q_out, self.encode_cnt
			elif ctrl == 1:
				q_out = 0b0010101011
				return q_out, self.encode_cnt
			elif ctrl == 2:
				q_out = 0b0101010100
				return q_out, self.encode_cnt
			else:
				q_out = 0b1010101011
				return q_out, self.encode_cnt

		# Now the DS part of TMDS (Differential Signaling):
		# if cnt reg is zero OR there are as many 1s as 0s in q_out[0:7]
		if (self.encode_cnt == 0) or \
				(CountOnesInData(q_m & 0xFF) == CountZerosInData(q_m & 0xFF)):
			q_out = invBit(getBit(q_m, 8)) << 9							# q_out[9] = ~q_m[8]
			q_out |= q_m & (1 << 8)										# q_out[8] =  q_m[8]
			q_out |= (q_m & 0xFF) if getBit(q_m, 8) else (~q_m & 0xFF)	# q_out[0:7] = (q_m[8] ? q_m[0:7] : ~q_m[0:7])

			# Count the DC inbalance 
			if getBit(q_m, 8): # Did we use XOR?
				# Add counter value with the ones minus the zeros
				# Cnt(t) = Cnt(t-1) + ( N_1{q_m[0:7]} - N_0{q_m[0:7]} )
				self.encode_cnt += CountOnesInData(q_m & 0xFF) - CountZerosInData(q_m & 0xFF)
			else:
				# Add counter value with the zeros minus the ones
				# Cnt(t) = Cnt(t-1) + ( N_0{q_m[0:7]} - N_1{q_m[0:7]} )
				self.encode_cnt += CountZerosInData(q_m & 0xFF) - CountOnesInData(q_m & 0xFF)
		else:
			if self.encode_cnt > 0 and \
					CountOnesInData(q_m & 0xFF) > CountZerosInData(q_m & 0xFF) or \
					self.encode_cnt < 0 and \
					CountZerosInData(q_m & 0xFF) > CountOnesInData(q_m & 0xFF):
				q_out = (1 << 9)
				q_out |= q_m & (1 << 8)
				q_out |= (~(q_m & 0xFF) & 0xFF)
				self.encode_cnt += (getBit(q_m, 8) * 2) + CountZerosInData(q_m & 0xFF) - CountOnesInData(q_m & 0xFF)
			else:
				q_out = (0 << 9)
				q_out |= q_m & (1 << 8)
				q_out |= (q_m & 0xFF)
				a = CountOnesInData(q_m & 0xFF)
				b = CountZerosInData(q_m & 0xFF)
				c = (invBit(getBit(q_m, 8)) * 2)
				self.encode_cnt += -(invBit(getBit(q_m, 8)) * 2) + CountOnesInData(q_m & 0xFF) - CountZerosInData(q_m & 0xFF)
		return q_out, self.encode_cnt
	
	def Decode(self, input : int) -> int:
		if input >= 2**10:
			raise ValueError("Value is more than 10 bit large!")

		# Do we have to invert the data?
		if input & (1 << 9):
			input = (input & 0x300) | (~input & 0xFF)
		
		q = input & (1 << 0)
		# XOR or XNOR?
		use_xnor = False if input & (1 << 8) else True

		for n in range(1, 8):
			# Bit is either 0 or 1, based on the logical operation
			a = getBit(input, n)
			b = getBit(input, n-1)
			bit = a ^ b
			if use_xnor:
				bit = 0 if bit else 1 # XNOR 
			q |= (bit << n)     

		return q

if __name__ == "__main__":
	# Manual / simple test of some "edge" cases
	TMDStest = TMDS()
	test_cases = [
		0x00, 0xFF, 0x55, 0xAA, 0x0F, 0xF0, 0x81, 0x7E, 0xFE, 0x01
	]

	for test_value in test_cases:
		tmds, cnt = TMDStest.Encode(test_value)
		print(f"Encoded value: {prettyPrintBinary(tmds,10)}, Count: {cnt}")

	# Automated test with stimuli/results pulled from the reference waveform found at
	# https://fpga.mit.edu/6205/F24/assignments/hdmi/tmds_ds
	error_cnt = 0
	print("Starting automated TMDS tests...")
	with open('tests/stimuli.csv', newline='') as csvfile:
		reader = csv.DictReader(csvfile, delimiter=';')
		tmds = TMDS()
		dc_balance = 0
		for idx, row in enumerate(reader, start=1):
			data_in = int(row['tmds_encoder.data_in'])
			de = bool(int(row['tmds_encoder.ve_in']))
			ctrl = int(row['tmds_encoder.control_in'])
			expected_q_out = int(row['tmds_encoder.q_out'])
			q_out, cnt = tmds.Encode(data_in, de, ctrl)
			q_in = tmds.Decode(q_out)
			if q_out != expected_q_out:
				print(f"Data in: {data_in:02x}, DE: {de}, CTRL: {ctrl}, Encoded: {prettyPrintBinary(q_out,10)}, Cnt: {cnt}")
				print(f"ERROR: Expected {expected_q_out:03x} at CSV row {idx}")
				error_cnt += 1
			if de and  q_in != data_in:
				error_cnt += 1
				print(f'Decoding failed!')

	if error_cnt == 0:
		print("All tests passed successfully!")
	else:
		print(f"{error_cnt} errors found during testing.")