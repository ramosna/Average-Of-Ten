TITLE Program Template     (template.asm)

; Author: Nathan Ramos
; Last Modified: 3/13/2021
; Description: This file contains program that prompts the user to enter 10 numbers that are within the
;			   range of a SDWORD. The numbers can be postive or negative. The program validates the user
;			   input letting the user know if what they inputted is correct. The program then takes the 
;			   string value inputted by the user and turns the array of numbers into numeric integer values.
;			   The numeric values are once again converted to ascii values and printed to show the user what
;			   values were entered. The converted integer values are used to calculate the sum and mean of
;			   all the numbers entered. The sum and mean are then also converted to ascii values and printed
;			   to the console screen.

INCLUDE Irvine32.inc

; Name: mGetString

; prints a prompt and takes user input

; Precondition: do not use edx, ecx, eax, or edi as arguments.

; Recieves: prompt = heading to be printed
; 			user_input = takes variable address to create array by user input
;			count = takes a value to determine length of user input
;			entered = takes variable address to store the number of values entered by user

mGetString	macro prompt, user_input, count, entered

	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	
	mDisplayString	prompt, 0, 0, 0
	mov		edx, user_input
	mov		ecx, count
	call	ReadString
	mov		edi, entered
	mov		[edi], eax


	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax

endm

; Name: mDisplayString

; takes an array and prints it

; Precondition: do not use edx or eax as arguments.

; Recieves: string_1 = string to be printed
; 			printType = takes an integer, if 0 - prints and does not CrLf, if 1 - prints and then CrLf
;			if and other integer - adds a comma and space after string printed.
;			comma = takes an array address to print comma
;			space = takes an array address to print space

mDisplayString	macro string_1, printType, comma, space
	local	_to_end
	local	_new_line
	push	edx
	push	eax

	mov		edx, string_1
	call	WriteString
	mov		eax, printType
	cmp		eax, 0
	je		_to_end
	cmp		eax, 1
	je		_new_line
	mov		edx, comma
	call	WriteString
	mov		edx, space
	call	WriteString
	jmp		_to_end

_new_line:
	call	CrLf
_to_end:

	pop		eax
	pop		edx


endm

; constants
BUFFER		=	33								; sets the limit of characters user can enter
INPUTS		=	10								; the number of integer inputs for the user


	

.data
	
	; variable for printing headers
	intro_1		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 13, 10,
						"programmed by: Nathan Ramos", 13, 10, 0
	intro_2		BYTE	"Please provide 10 signed decimal integers.", 13, 10,
						"Each number needs to be small enough to fit inside a 32 bit register. After you have finished", 13, 10,
						"inputting the raw numbers I will display a list of the integers, their sum, and their average", 13, 10, 
						"value.", 13, 10, 0
	prompt_1	BYTE	"Please enter a signed number: ", 0
	prompt_2	BYTE	"Please try again: ", 0
	error_1		BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
	num_enter	BYTE	"You entered the following numbers:", 13, 10, 0
	array_sum	BYTE	"The sum of all numbers entered is: ", 0
	array_mean	BYTE	"The rounded average is: ", 0
	goodbye_1	BYTE	"Thank you for using this program. Goodbye!", 0
	print_comma	BYTE	",", 0
	print_space	BYTE	" ", 0

	; variables for calculations
	numArray	SDWORD	INPUTS	DUP(?)
	numValue	SDWORD	?
	inputString	BYTE	BUFFER	DUP(?)
	byteInput	SDWORD	?
	stringArray	BYTE	12	DUP(?)
	revArray	BYTE	12	DUP(?)
	sum_num		SDWORD	?
	mean_num	SDWORD	?


.code
main PROC
	
	push	offset intro_2
	push	offset intro_1
	call	introduction
	
	push	offset error_1
	push	offset prompt_2
	push	offset prompt_1
	push	TYPE numArray
	push	BUFFER
	push	INPUTS
	push	offset inputString
	push	offset byteInput
	push	offset numValue
	push	offset numArray
	call	BuildArray
	
	push	offset print_space
	push	offset print_comma
	push	offset num_enter
	push	offset revArray
	push	offset stringArray
	push	INPUTS
	push	offset numArray
	call	PrintArray

	push	offset sum_num
	push	offset array_sum
	push	offset revArray
	push	offset stringArray
	push	INPUTS
	push	offset numArray
	call	SumNumbers
	
	push	offset array_mean
	push	offset revArray
	push	offset stringArray
	push	offset mean_num
	push	INPUTS
	push	sum_num
	call	MeanNumber

	push	offset goodbye_1
	call	goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; Name: introduction

; Description: This procedure prints two strings to the console window. The first intoduces the program
; author and title, the second explains how the program works. Produre uses mDisplayString macro to print
; the strings

; Preconditions:  The two arrays to be printed must be passed to the stack before the procedure is called. 
; mDisplayString must be defined and able to print passed string.

; Postconditions: The passed strings are printed to the console window.

; Receives: two array addresses
		; [ebp + 8]		= address of array/ first printed
		; [ebp + 12]	= address of array/ second printed

; Returns: The printed arrays

introduction PROC
	
	push	ebp
	mov		ebp, esp
	push	edx
	
	mDisplayString	[ebp + 8],	1, 0, 0
	mDisplayString	[ebp + 12],	1, 0, 0

	pop		edx
	pop		ebp
	ret		8

introduction ENDP

; Name: BuildArray

; Description: This procedure builds an array of integers based on user inputs. The procedure has a 
; subprocedure called ReadVal which prompts the user to enter a number within the given range. The
; subprocedure then takes each imput and converts it to an integer SDWORD. It passes the SDWORD to 
; BuildArray which then takes the SDWORD and adds it to the array.

; Preconditions: All variables used must be passed to the stack before the procedure is called. Every
; listed variables must have a either a value or memory address. 

; Postconditions: The array is built using integers. It is stored in the address passed to the procedure.

; Receives: memory address, constants
			; [ebp + 8]		= address of array/ Array to be build
			; [ebp + 12]	= address of Array value placeholder
			; [ebp + 16]	= addres of variable used to track number of user inputs
			; [ebp + 20]	= address of array of user inputs
			; [ebp + 24]	= contant/ length of array to be built
			; [ebp + 28]	= contant/ length of keys for valid user input
			; [ebp + 32]	= TYPE array to be built/ value of data type for incrementing edi
			; [ebp + 36]	= addres of array/ prompt to enter number
			; [ebp + 40]	= addres of array/ invalid input message 1
			; [ebp + 44]	= addres of array/ invalid input message 2

; Returns: The fully built array containing all the integers entered by the user, converted from thier orginial
; string inputs to numeric values. First value passed is the output variable. 

BuildArray PROC
	
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	mov		edi, [ebp + 8]							; the array of integers/ moving values used just within the procedure
	mov		ecx, [ebp + 24]							; number of elements in integer array/ number of times to loop
	mov		ebx, [ebp + 28]							; number of bytes for the string number input

	; values used by subprocedure
_adding_array:
	mov		eax, [ebp + 44]							; error message
	push	eax
	mov		eax, [ebp + 40]							; try again message
	push	eax
	mov		eax, [ebp + 36]							; prompt msg
	push	eax
	mov		eax, [ebp + 12]							; numValue/ the integer of one element to be added to the arraay
	push	eax
	mov		eax, [ebp + 16]							; keeps track of the amount of digits the user inputted
	push	eax
	mov		eax, [ebp + 20]							; user input variable
	push	eax
	push	ebx										; number of bytes for the string number input
	call ReadVal

	; adding to array / incrementing address
	mov		esi, [ebp + 12]							; moving the address of verified input
	mov		eax, [esi]								
	mov		[edi], eax
	add		edi, [ebp + 32]							; increments edi to recieve next value
	loop	_adding_array
	call	CrLf

	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		40

BuildArray ENDP

; Name: ReadVal

; Description: This procedure prompts the user to enter a number that is within range of a SDWORD. It
; then takes the input and validates if it is in range, and converts the user inputted string into the
; numeric form of the user's input. The integer is then put into an output variable and stored. It uses 
; two macros within the procedure. mGetString prompts the user to enter a number and takes the input and
; stores it. mDisplayString displays a string. 

; Preconditions: All variables used must be passed to the stack before the procedure is called. Every
; listed variables must have a either a value or memory address. The macros mGetString and mDisplayString
; must be defined. 

; Postconditions: The users input is converted from an array of ascii characters into its numeric form
; and stored in a sdword.

; Receives: memory address, constants
			; [ebp + 8]		= constant/ limit to number of characters user can input. 
			; [ebp + 12]	= address of Array/ the string of digits in ascii that the user entered
			; [ebp + 16]	= addres of variable/ the output variable that contains the numeric value
			; [ebp + 20]	= address of array/ store the inputs of user entered digits
			; [ebp + 24]	= addres of array/ prompt to enter number
			; [ebp + 28]	= addres of array/ invalid input message 1
			; [ebp + 32]	= addres of array/ invalid input message 2

; Returns: User input stored in [ebp + 16] memory address as numeric data. 

ReadVal PROC

	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	
	; prompt to enter number
_correct_input:
	mGetString		[ebp + 24], [ebp + 12], [ebp + 8], [ebp + 16]
	jmp		_verify

	; error message
_invalid_input:
	mDisplayString	[ebp + 32], 1, 0, 0
	mGetString		[ebp + 28], [ebp + 12], [ebp + 8], [ebp + 16]

	; verify if the input is correct/ creating string value
_verify:
	mov		esi, [ebp + 12]
	mov		edx, [ebp + 16]							; address of how many characters entered
	mov		ecx, [edx]								; moves value of characters entered
	cmp		ecx, 11
	jg		_invalid_input							; checks to see if they entered more than 11 digits
	mov		eax, 0
	mov		ebx, 0
	cld
	lodsb
	cmp		al, 43
	je		_leading_val							; seeing if there is a + or -
	cmp		al, 45
	je		_leading_val
	jmp		_no_sign
_valid_digit:
	lodsb
_no_sign:
	cmp		al, 48
	jl		_invalid_input
	cmp		al, 57
	jg		_invalid_input
	sub		al, 48
	push	eax
	mov		eax, ebx
	pop		ebx
	mov		edx, 10
	imul	edx
	jo		_invalid_input							; too big for register
	mov		edx, ebx
	mov		ebx, eax
	mov		eax, edx
	add		ebx, eax
	jo		_invalid_input							; too big for register

_leading_val:
	loop	_valid_digit

	; adding integer value to int variable
	mov		esi, [ebp + 12]
	mov		al, [esi]
	cmp		al, 45
	jne		_no_minus								; this is if the number was negative
	mov		eax, ebx
	mov		edx, -1
	imul	edx
	mov		ebx, eax

_no_minus:
	mov		edi, [ebp + 20]
	mov		[edi], ebx

	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		28

ReadVal ENDP

; Name: PrintArray

; Description: This procedure takes an array of integers and transfers them to a subprocedure called WriteVal,
; which converts the numeric integers into string form and then prints them. The procedure also uses a macro to
; print the heading.

; Preconditions:  All variables and values must be pushed to the stack before the procudure is called. The 
; macro mDisplayString must be defined.

; Postconditions: The array of integers is printed to the console window.

; Receives: array addresses and constant.
			; [ebp + 8]		= address of Array/ array of integers to be converted and printed
			; [ebp + 12]	= constant/ the number of elements in the array
			; [ebp + 16]	= addres of array/ used to copy single integer string value
			; [ebp + 20]	= addres of array/ used to take initial string value in reverse
			; [ebp + 24]	= addres of array/ used for printing header for macro
			; [ebp + 28]	= addres of array/ used for printing commas for macro
			; [ebp + 32]	= addres of array/ used for printing spaces for macro

; Returns: Prints the converted string array to the console window.

PrintArray PROC

	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	mDisplayString	[ebp + 24],	0, 0, 0				; prints display heading		
	
	mov		esi, [ebp + 8]
	mov		ecx, [ebp + 12]
	cld

	; pushes each value of array to be printed by WriteVal
_integer_str:
	lodsd
	push	[ebp + 32]
	push	[ebp + 28]
	push	ecx
	push	[ebp + 20]
	push	eax
	push	[ebp + 16]
	call	WriteVal
	loop	_integer_str

	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		28

PrintArray ENDP 

; Name: WriteVal

; Description: This procedure takes an integer and prints it to the console window. The procedure takes the 
; integer as numeric data and uses an algorithm to convert it into ascii characters so that it can be printed.
; It uses a macro called mDisplayString. 

; Preconditions:   All variables and values must be pushed to the stack before the procudure is called. The 
; macro mDisplayString must be defined.

; Postconditions: The header and integer is printed to the console window.

; Receives: array addresses, integer value
			; [ebp + 8]		= address of Array/ used to copy single integer string value
			; [ebp + 12]	= SDWORD integer value
			; [ebp + 16]	= addres of array/ used to take initial string value in reverse
			; [ebp + 20]	= value/ used to tell macro how to print
			; [ebp + 24]	= addres of array/ used for printing commas for macro
			; [ebp + 28]	= addres of array/ used for printing space for macro

; Returns: prints the converted string integer value to the console screen

WriteVal PROC

	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	; determining negative or postive value
	mov		ebx, [ebp + 12]
	cmp		ebx, 0
	jge		_non_negative
	mov		edi, [ebp + 8]						; move sorted string array address
	mov		al, 45
	mov		[edi], al
	mov		eax, ebx
	mov		ecx, -1								; converting to postive num
	imul	ecx
	mov		ebx, eax
	mov		eax, 1
	push	eax									; indicates num is negative
	jmp		_int_convert

	; convert num to ascii
_non_negative:
	mov		eax, 0
	push	eax
_int_convert:
	mov		edi, [ebp + 16]
	mov		ecx, 1
	cld
	cmp		ebx, 10
	jl		_single_dig
_keep_div:
	mov		eax, ebx
	mov		ebx, 10
	mov		edx, 0
	div		ebx
	mov		ebx, eax
	add		edx, 48
	mov		al, dl
	stosb
	inc		ecx
	cmp		ebx, 10
	jge		_keep_div

	; once there is only 1 digit left
_single_dig:
	add		ebx, 48
	mov		al, bl
	mov		[edi], al								; so memory address is pointing at last added value
	mov		esi, edi
	mov		edi, [ebp + 8]
	pop		eax
	cmp		eax, 0
	je		_rev_string
	inc		edi										; if there is a negative value added earlier

	; flipping backwards string
_rev_string:
	std
	lodsb
	cld
	stosb
	loop	_rev_string
	mov		eax, 0
	mov		[edi], eax

	; using macro to display value
	mDisplayString	[ebp + 8], [ebp + 20], [ebp + 24], [ebp + 28]


	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		24

WriteVal ENDP

; Name: SumNumbers

; Description: This procedure prints a header using a macro then takes an array of integers and sums up
; all the numbers in the array.The procedure then calls a subprocedure, WriteVal, to print out the
; resulting sum value.

; Preconditions: All variables and values must be pushed to the stack before the procudure is called. The 
; macro mDisplayString must be defined. Array must be SDWORD for addition algorithm to work

; Postconditions: None

; Receives: array addresses, constant
			; [ebp + 8]		= address of Array/ array to be added
			; [ebp + 12]	= Constant/ number of values in the array
			; [ebp + 16]	= address of Array/ used to copy integer string value
			; [ebp + 20]	= addres of array/ used to take initial string value in reverse
			; [ebp + 24]	= addres of value/ where the resulting sum is stored
			; [ebp + 28]	= addres of array/ header to be printed

; Returns: The header and sum of the array are printed to the console window. The sum value in the variable sum_num.

SumNumbers PROC

	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	; displays header
	mDisplayString	[ebp + 24], 0, 0, 0

	mov		esi, [ebp + 8]
	mov		ecx, [ebp + 12]
	mov		ebx, 0
	cld

	; calculates sum
_calc_sum:
	lodsd
	add		ebx, eax
	loop	_calc_sum
	mov		edi, [ebp + 28]
	mov		[edi], ebx

	; converts sum and prints it calling WriteVal
	mov		eax, 0
	push	eax
	push	eax
	mov		eax, 1
	push	eax
	push	[ebp + 20]
	push	ebx
	push	[ebp + 16]
	call	WriteVal


	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		24

SumNumbers ENDP

; Name: MeanNumber

; Description: This procedure takes two numbers and divides them by each other. It is assumed that the first
; number is the sum of a multiple integers and the second is the number of integers that were summed. Thus, the
; result is the average. The procedure prints a header using the macro mDisplayString and then calls the 
; subprocedure, WriteVal, to convert the mean to a string to be printed. The average is floor rounded.

; Preconditions: The dividend is assumed to be the sum, and the divisor is assumed to be the number of integers
; that was summed.

; Postconditions: The variable address for the mean is modified to hold the mean value.

; Receives: integer value, array addresses, constant
			; [ebp + 8]		= value of dividend/ sum
			; [ebp + 12]	= Constant/ value of divisor
			; [ebp + 16]	= address of variable/ used to store the mean value
			; [ebp + 20]	= address of Array/ used to copy integer string value - for subprocedure
			; [ebp + 24]	= addres of array/ used to take initial string value in reverse - for subprocedure
			; [ebp + 28]	= addres of array/ header to be printed

; Returns: The printed header and rounded mean value. The mean value in the variable mean_num.

MeanNumber PROC

	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	mDisplayString	[ebp + 28], 0, 0, 0				; print heading

	mov		eax, [ebp + 8]
	mov		ebx, [ebp + 12]
	cdq
	idiv	ebx
	mov		ebx, [ebp + 8]							; checking to see if num is positive
	cmp		ebx, 0	
	jge		_pos_mean								; if num is positive continue on
	cmp		edx, 0
	je		_pos_mean								; if the remainder is 0 continue on
	dec		eax										; in num is negative and has a remained/ floor rounded


_pos_mean:
	mov		edi, [ebp + 16]
	mov		[edi], eax

	; uses writeval to print mean
	mov		ebx, 0
	push	ebx
	push	ebx
	mov		ebx, 1
	push	ebx
	push	[ebp + 24]
	push	eax
	push	[ebp + 20]
	call	WriteVal

	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		24

MeanNumber ENDP

; Name: goodbye

; Description: Prints a goodbye message using a macro

; Preconditions:  the Macro mDisplayString must be defined 

; Postconditions: None

; Receives: array to be printed - [ebp + 8]

; Returns: Printed goodbye message

goodbye PROC

	push	ebp
	mov		ebp, esp
	push	edx

	call	CrLf
	mDisplayString	[ebp + 8],	1, 0, 0

	pop		edx
	pop		ebp
	ret		4

goodbye ENDP

END main
