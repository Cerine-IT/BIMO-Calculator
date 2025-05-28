# BIMO-Calculator
A simple calculator program written in x86 assembly language that performs arithmetic and bitwise operations on numbers in different bases (binary, hexadecimal, and decimal). The program features a graphical interface with a black result screen and colored buttons for input.

## Features
Supports three number bases:
  - Binary (b)
  - Hexadecimal (h)
  - Decimal (d)

Performs the following operations:
  - Addition (+)
  - Subtraction (-)
  - Multiplication (*)
  - Division (/)
  - Bitwise AND (&)
  - Bitwise OR (|)
  - Bitwise XOR (^)

Displays results in:
  - Binary format
  - Signed decimal format
  - Hexadecimal format

Shows processor flags after operations:
  - Zero Flag (ZF)
  - Sign Flag (SF)
  - Carry Flag (CF)
  - Overflow Flag (OF)

Handles division by zero errors

## Requirements
- DOS environment or DOS emulator (like DOSBox)
- MASM (Microsoft Macro Assembler) or compatible assembler

## How to Use
1. Assemble the program with MASM:
```bash
masm calcu.asm;
```
2. Link the object file:
```bash
link calcu.obj;
```
3. Run the executable:
```bash
calcu.exe
```

## Usage Instructions
1. When prompted, enter the base (b for binary, h for hexadecimal, d for decimal)
2. Enter the first operand
3. Enter the second operand
4. Choose an operation from the available options
5. The program will display:
  The result in binary, decimal, and hexadecimal formats
  The status of relevant processor flags

## Notes
The program uses DOS interrupts for input/output and BIOS interrupts for screen manipulation
The interface includes a title bar, a black result screen, and colored buttons representing numbers and operations
Negative numbers are supported in all bases
Division by zero is detected and displays an error message

## File Structure
calcu.asm: Main assembly source file containing all code and data

The program is self-contained with all necessary procedures for:
- Screen manipulation
- String input/output
- Number conversion
- Arithmetic operations
- Result display

## Limitations
Designed for 16-bit DOS environment.
Input numbers are limited to 16-bit values (-32768 to 32767).
The interface is text-based with simple color attributes.
