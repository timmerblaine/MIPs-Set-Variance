.data
ARRAY:	.space		20		# 20 bytes for 5 singles
MSG1:	.asciiz		"Prepare to enter five integers for the array.\n"
MSG2:	.asciiz		"Enter a number: "
MSG3:	.asciiz		"Floating Point List\n"
MSG4:	.asciiz		"\nThe Smallest Number is: "
MSG5:	.asciiz		"\nThe Largest Number is: "
MSG6:	.asciiz		"\nThe Mean of the numbers is: "
MSG7:	.asciiz		"\nThe Variance of the numbers is: "
EOL:	.byte		'\n'
SUM:	.asciiz		"\nHere's the sum: "
	.text
	.globl main
main:
	li	$v0,4
	la	$a0,MSG1
	syscall	
	addiu	$sp,$sp,-4	# Push one word of stack space
	sw	$ra,0($sp)	# Save current return address
	jal	FILL		# Jump and link to fill array
	lw	$ra,0($sp)	# Load contents of stack space back 
				# into return address ($ra)
	addiu	$sp,$sp,4	# Pop 4 bytes back
	jr	$ra		# End program
FILL:
	# Now we fill the array
	li	$t0,0		# array index set to 0
	li	$t1,5 		# $t1 = 5; Counter
	li.s 	$f3,0.0		# $f3 = 0.0 float; RunningSum inputs
TOP:
	li	$v0,4
	la	$a0,MSG2
	syscall
	li	$v0,5		# Prepare to read in an integer (Code 5)
	syscall			# Read in a number
	mtc1	$v0,$f0		# Put the input into FP register
	cvt.s.w	$f0,$f0		# Convert integer input into single float
	swc1	$f0,ARRAY($t0)	# Save $v0 = input single into ARRAY[0]
	addiu	$t0,$t0,4	# Add 4 bytes to ARRAY to get ARRAY[1]
	addiu	$t1,$t1,-1	# Subtract 1 from counter
	add.s	$f3,$f3,$f0	# $f3 = $f3 + $f0; Running Sum
	bne	$t1,$zero,TOP	# if ($t1 != 0) jump to FILL

	addiu	$t0,$t0,-20	# Subtract 20 to return to first cell of array
	addiu	$t1,$zero,5	# Make $t1 = 5
	li	$v0,4
	la	$a0,MSG3
	syscall	
PRINT:
	# Check to see if it worked via print out ARRAY[0]
	li 	$v0,2		# Prepare to print a single float (Code 2)
	lwc1	$f12,ARRAY($t0)	# Load word Mem[0+$t0] = $a0
	syscall			# Print loaded int
	li	$v0,11		# Prepare to print a byte
	lb	$a0,EOL		# Print byte endl
	syscall
	addiu	$t0,$t0,4	# Add 4 bytes to ARRAY to get ARRAY[1]
	addiu	$t1,$t1,-1	# Subtract 1 from counter
	bne	$t1,$zero,PRINT	# if ($t1 != 0) jump to FILL

	# Now print running sum
	li	$v0,4
	la	$a0,SUM
	syscall
	li 	$v0,2
	mov.s	$f12,$f3	# Load $f3 (RunSum) into $f12
	syscall
	mov.s	$f6,$f3		# Move $f3 (RunSum) into $f6 to save

	# Now we find the smallest and largest of the array
	addiu	$t0,$t0,-20	# Reset array index back to 0
	addiu	$t1,$zero,5	# Reset counter to 5
	lwc1	$f0,ARRAY($t0)	# Set the ARRAY[0] to Min; $f0 will be	Min
	mov.s	$f1,$f0		# Make first index Max and Min; $f1 will be Max
SORT:	
	lwc1	$f2,ARRAY($t0)	# $f3 = ARRAY[$f0]
	c.lt.s	$f2,$f0		# If ($f2 < $f0) then code = 1, else code = 0
	bc1t	SETMIN		# If (code == 1) then jump to SETMIN
	c.lt.s	$f1,$f2		# If ($f1 < $f2) then code = 1, else code = 0
	bc1t	SETMAX		# If (code == 1) then jump to SETMAX
	addiu	$t0,$t0,4	# Add 4 bytes to ARRAY to get ARRAY[1]
	addiu	$t1,$t1,-1	# Subtract 1 from counter
	beq	$t1,$zero,ENDSORT	# if ($t1 == 0) jump to ENDSORT
	j	SORT		# If ($t1 != 0) at this point, jump to SORT
SETMIN:
	mov.s	$f0,$f2		# $f0 (Min) = $f3 (Current Array Value)
	j	SORT		# Jump to SORT
SETMAX:	
	mov.s	$f1,$f2		# $f1 (Max) = $f3 (Current Array Value)
	j	SORT		# Jump to SORT
ENDSORT:
	li	$v0,4
	la	$a0,MSG4
	syscall	
	li 	$v0,2
	mov.s	$f12,$f0	# Load $f0 (Min) into $f12
	syscall			# Print Min
	li	$v0,4
	la	$a0,MSG5
	syscall	
	li 	$v0,2
	mov.s	$f12,$f1	# Load $f1 (Max) into $f12
	syscall			# Print Max
	
	# Now Print Mean; Mean = Sum / 5
	li.s	$f4,5.0		# $f4 = 5.0, since we have 5 numbers in array
	div.s	$f4,$f3,$f4	# $f4 = $f3 / $f4; $f4 = Sum / 5
	li	$v0,4
	la	$a0,MSG6
	syscall	
	li	$v0,2
	mov.s	$f12,$f4	# Print mean
	syscall

	# Now Calculate the variance;
	# $f6 = RunSum; $f4 = Mean
	li	$t0,0			# Array index
	li	$t1,5			# Counter
	li.s	$f2,0.0		# Clear register to hold summation

GETV:	
	lwc1	$f1,ARRAY($t0)	# Load word Mem[0+$t0]
	sub.s	$f1,$f1,$f4	# $f1 = $f1 - $f4(Mean)
	mul.s	$f1,$f1,$f1	# $f1 = $f1 * $f1, or $f1^2
	add.s	$f2,$f2,$f1	# $f2 = $f2 + $f1

	addiu	$t0,$t0,4	# Add 4 bytes to ARRAY to get ARRAY[1]
	addiu	$t1,$t1,-1	# Subtract 1 from counter
	bne	$t1,$zero,GETV	# if ($t1 != 0) jump to GETV

	li.s	$f0,4.0		# Since 4 = 5-1, the denominator under the summation
	div.s	$f1,$f2,$f0	# $f2 = $f2/ 4.0

	li	$v0,4
	la	$a0,MSG7
	syscall	
	li	$v0,2
	mov.s	$f12,$f1	# Print Variance calculated above
	syscall

	jr	$ra		# Jump to saved sort on line 17
