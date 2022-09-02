.include "./cs47_proj_macro.asm"
.include "./cs47_common_macro.asm"
.text
.globl au_logical
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:

	addi	$sp, $sp, -24
	sw	$fp, 24($sp)
	sw	$ra, 20($sp)
	sw	$a0, 16($sp)
	sw	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi	$fp, $sp, 24

	beq $a2, '+', log_add
	beq $a2, '-', log_sub
	beq $a2, '/', log_div
	beq $a2, '*', log_mul

	
	log_add:
	#v0 - answer, t0 - counter, t1 - a, t2 - b, t3- CI/CO, t4 - sum
	
	li $a2, 0x0 #reset $a2
	j add_or_sub_reset
	
	log_sub:
	li $a2, 0xFFFFFFFF
	
	add_or_sub_reset:
	li $v0, 0   #set answer to 0
	li $t0, 0 #set counter to 0
	li $t4, 0 #set sum to 0
	extract_nth_bit($t3,$a2,$zero)  #set CI to last digit of $a2
	beqz $t3, add_helper #if CI is 0, operation is addition
	
	sub_helper:
	not $a1, $a1 #negate $a1
	
	add_helper:
	extract_nth_bit($t1,$a0,$t0) # set a to the digit of addend1 at counter
	extract_nth_bit($t2,$a1,$t0) # set b to the digit of addend2 at counter
	
	xor $t5, $t1, $t2 #set t5 to (a xor b)
	and $t6, $t1, $t2 #set t6 to (a and b)
	
	and $t7, $t3, $t5 #set t7 to CI and (a xor b)
	xor $t4, $t5, $t3 #set sum to CI xor (a xor b)
	or $t3, $t7, $t6 #set CO to ((CI and (a xor b)) or (a and b)
	
	insert_to_nth_bit($v0,$t0,$t4,$t5) #set the digit of the answer at counter to sum
	
	add $t0,$t0,1 #increment the counter
	blt $t0,32,add_helper #if counter < 32, rerun add_helper 
	move $v1,$t3 #move the last CO to $v1
	
	
	add_helper_end:
	j end
	
	log_mul: 
	jal mul_signed
	j end
	
	log_div:
	jal div_signed
	j end
	
	end:	
	lw	$fp, 24($sp)
	lw	$ra, 20($sp)
	lw	$a0, 16($sp)
	lw	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 24
	jr 	$ra
	

twos_complement:
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)
	sw	$a1, 8($sp)
	addi 	$fp, $sp, 20

	not $a0,$a0 #negate $a0
	li $a1, 1 #set $a1 to 1
	li $a2, '+' #set $a2 to "+"
	jal au_logical #call au_logical which will add $a0 and $a1, incrementing $a0 by 1, and store it in $v0
	
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1, 8($sp)
	addi	$sp, $sp, 20
	jr $ra

twos_complement_if_neg:
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)
	sw	$a1, 8($sp)
	addi 	$fp, $sp, 20

	bltz $a0, numIsNeg #skip to numIsNeg if $a0 is negative
	move $v0,$a0 #since $a0 is not negative, set $v0 to $a0
	j end_twos_comp #skip to end_twos_com
	
	numIsNeg:
	jal twos_complement #run twos_complement
	
	end_twos_comp:
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1, 8($sp)
	addi	$sp, $sp, 20
	jr $ra
	
	
twos_complement_64bit:
	#$t0 is $a0, $t1 is a1, $a0 is first number, $a1 is second number, $a2 operation +
	addi	$sp, $sp, -28
	sw	$fp, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw 	$a2, 12($sp)
	sw  	$s1, 8($sp)
	addi $fp, $sp, 28
	
	not $a0, $a0 #negate $a0
	move $s1, $a1 #store $a1 in $s1 
	li $a1, 1 #set $a1 to 1
	
	li $a2, '+' #set $a2 to "+"
	jal au_logical #run au_logical, which will add 1 to $a0 and store the result in $v0
	
	move $a0, $s1 #set $a0 to $s1, which was the original $a1
	not $a0, $a0 #negate $a0
	move $a1, $v1 #set $a1 to $v1, which copies the CO from the first addition to this new addition
	move $s1, $v0 #store $v0 in $s1, which was the result of the original addition (!$a0 + 1)

	li $a2, '+' #set $a2 to "+"
	jal au_logical #run au_logical, wich will add the CO from the first addition (stored in $a1) to $a0
	
	move $v1, $v0 #set $v1 to $v0, which should be the high part of the result
	move $v0, $s1 #reset $v0 with its stored value in $s1, which should be the low part of the result
	
	lw	$fp, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw 	$a2, 12($sp)
	lw  	$s1, 8($sp)
	addi	$sp, $sp, 28
	jr $ra

bit_replicator:	
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a0, 8($sp)
	addi	$fp, $sp, 16
	
	beqz $a0,repeating_zero #If $a0 is equal to 0, skip to repeating_zero
		
	li $v0, 0xFFFFFFFF #Load $v0 with replicated F's
	j skip_to_end_replicator #Skip past repeating_zero 
	
	repeating_zero:
	li $v0, 0x00000000 #Load $v0 with replicated 0's
	
	
	skip_to_end_replicator:
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a0, 8($sp)
	addi	$sp, $sp, 16
	jr $ra
	
mul_unsigned:
	
	addi	$sp, $sp, -40
	sw      $s4, 40($sp) #Hi
	sw      $s3, 36($sp)
	sw	$fp, 32($sp)
	sw 	$s2, 28($sp)#multiplier 
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp) 
	sw	$s1, 8($sp) #multiplicand M
	addi	$fp, $sp, 3
	                                                                                #v0 - answer, a0 - multiplicand, a1 - multiplier, s0 - counter
	li $s4, 0
	li $s3, 0
	
	li $s0, 0                                                                                   #Resets counter to 0
	li $v1, 0                                                                                   #Set $v1 to 0. Resets H to 0. n
	                                                                                  #move $v0, $a1 #Stores #a1 in $v0
	mult_helper:
	extract_nth_bit($t1,$s2,$zero)                                                                                   #sets $t1 to the bit of $v0 at position zero
	
	move $a0, $t1
	jal bit_replicator

	move $t1, $v0                                                                                   #move replicated bit to $t1
	
	and $s3, $t1, $s1                                                                                       #$s3 = x
	move $a0, $s4
	move $a1, $s3
	li $a2,                                                                                   '+'
	                                                                                  #exit()
	jal au_logical                                                                                   #Hi + x
	
	move $s4, $v0                                                                                   #Hi = Hi + x
	                                                                                  #exit()
	srl $s2, $s2, 1
	li $t0, 0
	extract_nth_bit($t1, $s4, $t0)
	srl $s4, $s4, 1
	
	li $t0, 31
	li $t5, 0
	insert_to_nth_bit($s2, $t0, $t1, $t5)
	addi $s0, $s0, 1
	bne $s0, 32, mult_helper
	
	move $v0, $s2
	
	
	lw      $s4, 40($sp)
	lw      $s3, 36($sp)
	lw	$fp, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 40
	jr $ra

mul_signed:
	
	addi	$sp, $sp, -32
	sw	$fp, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi 	$fp, $sp, 32
	
	move $s1, $a0                                                                                    #Stores $a0 in $s1
	move $s2, $a1                                                                                   #Stores $a1 in $s2
	
	bgez $a0,skip1                                                                                   #If $a0 is less than 0, run the following line. 
	jal twos_complement
	move $s0, $s1
	
	move $s1, $v0                                                                                   #Stores $v0 in $a1, $s1 is multiplicand #1
	
	skip1:	                                                                                  #move $s0, $v0 #Stores $v0 in #s0
	                                                                                  #move $a0, $a1 #Stores $a1 in $a0
	move $a0, $a1                                                                                   #Stores $s2 in $a0
	
	bgez $a0,skip2                                                                                   #If $a1 is greater or equal to 0, skip to skip2
	jal twos_complement
	move $a1,$s2                                                                                   #restore $a1
	move $s2, $v0 
	
	skip2:
	move $a0, $s0                                                                                   #restores $s0 in $a0
	
	jal mul_unsigned
	
	move $t5, $v0
	
	li $t2, 31
	extract_nth_bit($t0, $a0, $t2)                                                                                   #sets $t0 to the bit of $a0 at position $t2
	extract_nth_bit($t1, $a1, $t2)                                                                                   #sets $t1 to the bit of $a1 at position $t2
	move $a0, $v0                                                                                   #Stores $v0 in $a0
	move $a1, $v1                                                                                   #Stores $v1 in $a1
	xor $t0, $t0, $t1                                                                                   #Set $t0 to $t0 XOR $t1
	beqz $t0, mul_finish                                                                                   #If $t0 is equal to 0, skip ahead to mul_finish
	
	jal twos_complement_64bit
	
	mul_finish:
	lw	$fp, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 32
	jr $ra
	
	

div_unsigned:
	
	addi	$sp, $sp, -40
	sw	$s4, 40($sp)
	sw	$s3, 36($sp)
	sw	$fp, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi	$fp, $sp, 40
	
	#s0 - quotient, $s1 - divisor, $s2 - remainder, $s3 - counter
	li $s3, 0
	
	
	div_loop:
	sll $s2, $s2, 1
	
	li $t0, 31
	extract_nth_bit($t1, $s0, $t0)
	li $t0, 0
	insert_to_nth_bit($s2, $0, $t1, $t0)
	
	sll $s0, $s0, 1
	move $a0, $s2
	move $a1, $s1
	li $a2, '-'
	jal au_logical
	
	move $s4, $v0
	bltz $s4, skip5
	
	move $s2, $s4
	li $t0, 1
	li $t2, 0
	insert_to_nth_bit($s0, $zero, $t0, $t2)
	
	skip5:
	addi $s3, $s3, 1
	bne $s3, 32, div_loop
	
	move $v0, $s0
	move $v1, $s2

	lw	$s4, 40($sp)
	lw	$s3, 36($sp)
	lw	$fp, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 40
	jr $ra	
	
div_signed:

	addi	$sp, $sp, -40
	sw	$fp, 40($sp)
	sw 	$s4, 36($sp)
	sw	$s3, 32($sp)
	sw 	$s2, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi 	$fp, $sp, 40
	
	move $s0, $a0 #S0 - divident / quotient
	move $s1, $a1 #S1 - divisor
	
	li $s2, 0 #$s2 - remainder
	
	move $s3, $a0 
	
	bgtz $s0, skip3
	jal twos_complement
	move $s0, $v0
	
	skip3:
	
	bgtz $s1, skip4
	move $a0, $s1
	jal twos_complement
	move $s1, $v0
	move $a0, $s3
	
	skip4:
	
	jal div_unsigned
	move $s2, $v0
	move $s3, $v1
	
	li $t0, 31
	extract_nth_bit($s0, $a0, $t0)

	extract_nth_bit($t2, $a1, $t0)
	xor $t3, $s0, $t2
	
	bne $t3, 1, skip6
	move $a0, $s2
	jal twos_complement
	
	move $s2, $v0
	
	skip6:
	bne $s0, 1, skip7
	move $a0, $s3
	jal twos_complement
	move $s3, $v0
	skip7:
	move $v0, $s2
	move $v1, $s3
	
	lw	$fp, 40($sp)
	lw 	$s4, 36($sp)
	lw	$s3, 32($sp)
	lw 	$s2, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	
	addi	$sp, $sp, 40
	jr $ra

	
