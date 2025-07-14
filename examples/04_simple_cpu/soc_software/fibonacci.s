; Fibonacci program demo
; This fibonacci demo calculates the first 8 values in the fibonacci sequence
; and writes them to incrementing IO addresses, starting with the address zero.
;
; The calculated value is also output through the GPIO port (address 0x10).
;
; This program is also used as a GPIO-less version in the the "tb_overture.vhdl" 
; testbench, allowing to check the correct execution by observing the simulated
; RAM contents for the fibonacci sequence.
; 

TOP_ADDR    EQU 7	 ; Add one to get the total amount of fibonacci values

IO_GPIO     EQU 0x10 ; Address of the GPIO peripheral in the IO address space
IO_DELAY_US EQU 0x11 ; Address of the delay counter in the IO address space
IO_DELAY_MS EQU 0x12
IO_DELAY_S  EQU 0x13

; LJNZ for LDI + JNZ... Or should I name it LNZ?
%macro LJNZ addr   
    LDI addr
	JNZ
%endmacro

; Initialize fibonacci
start:
    LDI #00        
	MOV R6, R0     ; Set the IO address pointer to zero
    MOV R4, R0     ; R4 holds one of the number sequences
	LDI 0b1
	MOV R5, R0     ; R5 holds the other fib number

; Fibonacci loop from here
loop:
	MOV IO, R4     ; Output the newest fibonacci value into RAM
	MOV R1, R6     ; Backup the current IO RAM pointer
	LDI IO_GPIO    ; Load in the IO address of the GPIO peripheral
	MOV R6, R0
	OUT R4         ; Output the newest fibonacci value to GPIO / LEDs
	MOV R6, R1     ; 

; Perform the next fibonacci calculation cycle f_n = f_{n-1} + f_{n-2}
	MOV R1, R4
	MOV R2, R5
	OP ADD         ; R3 = R1 + R2 
	MOV R4, R5     ; current <- next
	MOV R5, R3     ; next <- sum

; ###### For simulation purposes, you might want to uncomment from here....
; Wait for 256 milliseconds (so we can see how it calculates things)
	LDI 0          ; We can only load values of 0x3F (63), but we can
	MOV R1, R0     ; Load in zero and subtract one from it, giving 0xFF
	LDI 1
	MOV R2, R0
	OP SUB         ; R3 holds now 0xFF after this instruction

	; Save R6 - We don't need R1 and R2 anymore, so store it there
	MOV R1, R6

	; Load in the address of the delay milliseconds counter
	LDI IO_DELAY_MS
	MOV R6, R0
	; Load the amount of ms we want to wait to the delay peripheral
	MOV IO, R3

delay_ms:
	; Read the value of the delay peripheral
	MOV R3, IO
	; If it has reached zero, the wait is over - otherwise loop around
	LJNZ delay_ms

	; Restore R6
	MOV R6, R1
; ###### ... until here. Otherwise the simulation will take ~15 minutes to
; simulate two seconds! Reassemble it specifically for simulations.
	
; Increment IO address pointer *(IO++)
	LDI 1
	MOV R1, R0
	MOV R2, R6
	OP ADD
	MOV R6, R3
	
; Have we already reached IO address 7? (basically output 8 values)
	LDI TOP_ADDR
	MOV R1, R0
	; Still got the old IO address in R2 - going to repurpuse it
	OP SUB          ; Subtract R1 from R2
	
	;LDI loop       ; Load in the start of the loop
	;JNZ            ; If it's not zero, we haven't reached the end yet - loop around
	LJNZ loop		; This macro performs the same as the above two, commented-out instructions

; If we got here, then we have calculated the amount of required fibonacci sequences
; Stop the CPU
	HLT
