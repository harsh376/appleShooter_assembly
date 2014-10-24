# .include "nios_macros.s"
.equ PS2_KEYBOARD_DATA, 0x10000100
.equ PS2_KEYBOARD_CONTROL, 0x10000104
.equ GREEN_LEDS, 0x10000010
.equ ADDR_7SEG1, 0x10000020
.equ ADDR_7SEG2, 0x10000030

.section .exceptions, "ax"

IHANDLER:
	# rdctl et, ctl4				# read ipending : ctl4
	# andi et, et, 0x80			# 0x80 = 0000 0000 1000 0000
	# movi r20, 0x1 					
	# mov r17, r0
	# beq et, r0, EXIT_HANDLER	# checking if IRQ 7 is pending (i.e ps/2)

rdctl et, ctl4
andi et, et, 0x1 						 #check if interrupt pending IRQ0 - highest priority (TIMER)
bne	 et, r0, TIMER1

rdctl et, ctl4
andi et, et, 0x80                          #check for bit 7
bne et, r0, KEYBOARD


TIMER1:
# do something
movi et, 30
beq r16, et, LOSE
addi r16, r16, 1

# send ACK for TIMER
movia et, TIMER
stwio r0, 0(et)				
br EXIT_HANDLER

KEYBOARD:
	ldwio r12, 0(r8)			# loading the data
	movi r13, 0xff					
	and r12, r12, r13			# bits [7:0] from data register

UP_KEY:
	cmpeqi et, r12, 0x75
	beq et, r0, DOWN_KEY
	movi et, 128
	bgt r23, et, EXIT_HANDLER
	addi r23, r23, 5
	movia r17, RED_LEDS
	# movui r18, 1
	stwio r23, 0(r17)
	br EXIT_HANDLER

DOWN_KEY:
	cmpeqi et, r12, 0x72
	beq et, r0, LEFT_KEY
	addi r23, r23, -5
	movia r17, RED_LEDS
	# movui r18, 1
	stwio r23, 0(r17)
	br EXIT_HANDLER


LEFT_KEY:
	cmpeqi et, r12, 0x6b
	beq et, r0, RIGHT_KEY
	addi r21, r21, -5
	movia r17, GREEN_LEDS
	# movui r18, 1
	stwio r21, 0(r17)
	br EXIT_HANDLER

RIGHT_KEY:
	cmpeqi et, r12, 0x74
	beq et, r0, ENTER
	movi et, 130
	bgt r21, et, EXIT_HANDLER
	addi r21, r21, 5
	movia r17, GREEN_LEDS
	# movui r18, 1
	stwio r21, 0(r17)
	br EXIT_HANDLER


ENTER:
	cmpeqi et, r12, 0x5a
	beq et, r0, EXIT_HANDLER
	# movia r17, GREEN_LEDS
	movui r22, 1
	# stwio r22, 0(r17)
	br EXIT_HANDLER



EXIT_HANDLER:
	subi ea, ea, 4
	eret

###########################################################
.text

.equ TOP_OF_MEMORY, 0X1000
.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000
.equ TIMER, 0x10002000
.equ PERIOD, 0x30D40			#timer period of 1 second
.equ RED_LEDS, 0x10000000
.equ INTERRUPT_PERIOD, 0x2FAF080			#timer period of 1 second

.global main,INITIALIZE_TIMER, PLOT_5x5_SQUARE, COLLISION, PLOT_TANK, PLOT_RIGHT_DIAGONAL, PLOT_RECTANGLE, PLOT_LEFT_DIAGONAL, TIMER_BAR, CLEAR_SCREEN

main:
	addi sp, sp, -40

	movia sp, TOP_OF_MEMORY		# initializing address for stack pointer


	mov r18, r0
	movi r19, 1  			# r14 : level

	# call plotTimer


NEW_ATTEMPT:

	movia r2, GREEN_LEDS
	movi r3, 0
	# movui r18, 1
	stwio r3, 0(r2)
	
	movia r2, RED_LEDS
	movi r3, 0
	stwio r3, 0(r2)

	movi r17, 6
	bgt r18, r17, LOSE

	movia r8, PS2_KEYBOARD_DATA
	movia r9, PS2_KEYBOARD_CONTROL
	
	movi r23, 0 			# up-down counter
	movi r22, 0 			# enter
	movi r21, 0  			# left-right counter
	movi r16, 0 			# time left

	ldwio r10, 0(r9)		# reading from 4(keyboard) control bits
	movi r11, 0x1
	or r10, r11, r10
	stwio r10, 0(r9)		# configure device : PS/2
	

	movia r9, TIMER 		# configure device : TIMER
	movui r10, %lo(INTERRUPT_PERIOD)
	stwio r10, 8(r9)
	movui r10, %hi(INTERRUPT_PERIOD)
	stwio r10, 12(r9)
	stwio r0, 0(r9)
	movi r10, 0b111
	stwio r10, 4(r9)


	movi r11, 0x81

	wrctl ctl3, r11			# enable IRQ7(PS2), IRQ0(TIMER) : ctl3
	movi r11, 0x1
	wrctl ctl0, r11			# enable external interrupts : ctl0 / PIE

	movi r20, 1
	initial:					# loop till interrupt occurs
		movi r10, 10
	loop:
		beq r22, r20, EXIT_LOOP
		subi r10, r10, 1
		bne r10, r0, loop
		br initial 	
		

	EXIT_LOOP:
		# movia r2,ADDR_7SEG1
		# movia r3,0b0111111001111110011111100111111
		# stwio r3,0(r2)
		# movia r2,ADDR_7SEG2
		# stwio r3, 0(r2)


	END5:		
		mov r11, r0
		movi r11, 0x1
		wrctl ctl3, r11			# disable IRQ7(PS/2), enable IRQ0(TIMER) : ctl3
		# wrctl ctl0, r11			# disable external interrupts : ctl0 / PIE




	# movi r4, 0
	# movi r5, 0
	# call getCoordinates
	# mov r8, r2
	# mov r9, r3


	# movui r4,0xffff  		# White pixel
	# movi  r5, 0x41   		# ASCII for 'A'

	# call clearScreen		# flush the background

	# call displayTextLCD

	call CLEAR_SCREEN

	call target

# # target
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0x9900
# 	movui r5, 300
# 	movui r6, 150
# 	movui r7, 0x5

# 	call PLOT_5x5_SQUARE 	# PLOT_5X5_SQUARE(r4, r5, r6)
# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)

# # head
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0xcc66
# 	movui r5, 298
# 	movui r6, 155
# 	movui r7, 0xc

# 	call PLOT_5x5_SQUARE 	# PLOT_5X5_SQUARE(r4, r5, r6)
# 	# call PLOT_HEAD

# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)



# # neck
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0xcc33
# 	movui r5, 303
# 	movui r6, 167
# 	movui r7, 0x2

# 	call PLOT_RECTANGLE 	# PLOT_5X5_SQUARE(r4, r5, r6)
	
# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)


# # left arm
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0x66ff
# 	movui r5, 302
# 	movui r6, 175
# 	movui r7, 0x6

# 	call PLOT_LEFT_DIAGONAL 	# PLOT_5X5_SQUARE(r4, r5, r6)

# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)



# # right arm
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0x66ff
# 	movui r5, 305
# 	movui r6, 175
# 	movui r7, 0x6

# 	call PLOT_RIGHT_DIAGONAL 	# PLOT_5X5_SQUARE(r4, r5, r6)

# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)



# # left leg
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0x66ff
# 	movui r5, 302
# 	movui r6, 202
# 	movui r7, 0x6

# 	call PLOT_LEFT_DIAGONAL 	# PLOT_5X5_SQUARE(r4, r5, r6)

# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)



# # right leg
# 	stw r8, 0(sp)
# 	stw r9, 4(sp)
# 	stw r10, 8(sp)
# 	stw r11, 12(sp)
# 	stw r12, 16(sp)
# 	stw r13, 20(sp)
# 	stw r14, 24(sp)
# 	stw r15, 28(sp)

# 	movui r4, 0x66ff
# 	movui r5, 305
# 	movui r6, 202
# 	movui r7, 0x6

# 	call PLOT_RIGHT_DIAGONAL 	# PLOT_5X5_SQUARE(r4, r5, r6)

# 	ldw r8, 0(sp)
# 	ldw r9, 4(sp)
# 	ldw r10, 8(sp)
# 	ldw r11, 12(sp)
# 	ldw r12, 16(sp)
# 	ldw r13, 20(sp)
# 	ldw r14, 24(sp)
# 	ldw r15, 28(sp)


# 	movi r10, 30 				# r5(x-coordinate) : second paramter to function plot_5x5_square
# 	movi r11, 30				# r6(y-coordinate) : third parameter to function plot_5x5_square
# 	movi r12, 315				# for now have defined an end point

	


	# mov r4, r21
	# mov r5, r23
	# movui r4, 100
	# movui r5, 80
	
	# movui r4, 3
	mov r4, r19
	call tank

	# movui r4, 3
	mov r4, r19
	mov r5, r21
	mov r6, r23  

	call proj
	mov r6, r2
	movi r7, 2 
	beq r6, r7, LOSE  

	movi r7, 1
	beq r6, r7, HIT_TARGET

	addi sp, sp, 40
	addi r18, r18, 1
	br NEW_ATTEMPT

HIT_TARGET:
	movi r7, 3
	beq r19, r7, WON

	mov r18, r0
	addi r19, r19, 1
	addi sp, sp, 40

br NEW_ATTEMPT
  # br END

LOSE:
	movia r4, ADDR_7SEG2
	movia r5, 0b1101110001111110011111000000000
	stwio r5, 0(r4)
	movia r4, ADDR_7SEG1
	movia r5, 0b0111000001111110110110101111001
	stwio r5, 0(r4)

	# movia r4,RED_LEDS  				# load address of LEDs
	# movui r5, 0x20000;
	# stwio r5, 0(r4)
	br END

WON:
	
	movia r4, ADDR_7SEG2
	movia r5, 0b1110011011110010101000001110001
	stwio r5, 0(r4)
	movia r4, ADDR_7SEG1
	movia r5, 0b1111001001110010111100000001000
	stwio r5, 0(r4)

	movia r4,RED_LEDS  				# load address of LEDs
	movui r5, 0x10000;
	stwio r5, 0(r4)
	br END	

	

# myFunc:
# 	addi sp, sp, -48
# 	stw ra, 0(sp)
# 	stw r16, 4(sp)
# 	stw r17, 4(sp)
# 	stw r18, 4(sp)
# 	stw r19, 4(sp)
# 	stw r20, 4(sp)
# 	stw r21, 4(sp)
# 	stw r22, 4(sp)
# 	stw r23, 4(sp)	

# 	movi r8, 1000			# N
# 	movi r9, 10 			# g

# 	mov r10, r4 			# vel
# 	mov r11, r5 			# theta

# 	mov r4, r10
# 	muli r5, r11, 180		# theta_in_radians
# 	call vComp
# 	mov r12, r2 			# v_x
# 	mov r13, r3 			# v_y


# 	ldw ra, 0(sp)
# 	ldw r16, 4(sp)
# 	ldw r17, 4(sp)
# 	ldw r18, 4(sp)
# 	ldw r19, 4(sp)
# 	ldw r20, 4(sp)
# 	ldw r21, 4(sp)
# 	ldw r22, 4(sp)
# 	ldw r23, 4(sp)	
	
# 	addi sp, sp, 48
# 	ret





PLOT_RIGHT_DIAGONAL:

	addi sp, sp, -52

	# r4 : colour
	# r5 : initial x-coordinate
	# r6 : initial y-coordinate
	# r7 : length of diagonal

	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)
	stw r4, 36(sp)
	stw r5, 40(sp)
	stw r6, 44(sp)
	stw r7, 48(sp)

	mov r9, r7 						# upper bound for i
	# mov r9, r7   					# upper bound for j

	# start inner loop
	mov r18, r0 					# j=0

	INNER_LOOP_PLOT_RDIAG:

	bge r18, r9, EXIT_INNER_PLOT_RDIAG	# for j<5

	# plot the pixel
	movia r16,ADDR_VGA				# getting the initial device (VGA) address
	muli r19, r5, 2 				# effective x-coordinate
	muli r20, r6, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21
	# r21 = mem. location of top left pixel of (x,y)

	muli r19, r17, 2 				# effective x-coordinate
	muli r20, r18, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21				# adding the memory offset initial VGA address
	sthio r4,(r16) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */


	addi r5, r5, 1
	addi r6, r6, 1

	addi r18, r18, 1
	br INNER_LOOP_PLOT_RDIAG

	EXIT_INNER_PLOT_RDIAG:

	ldw r4, 36(sp)
	ldw r5, 40(sp)
	ldw r6, 44(sp)
	ldw r7, 48(sp)	

	ldw r23, 32(sp)
	ldw r22, 28(sp)
	ldw r21, 24(sp)
	ldw r20, 20(sp)
	ldw r19, 16(sp)
	ldw r18, 12(sp)
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)

	addi sp, sp, 52
	ret



PLOT_LEFT_DIAGONAL:

	addi sp, sp, -52

	# r4 : colour
	# r5 : initial x-coordinate
	# r6 : initial y-coordinate
	# r7 : length of diagonal

	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)
	stw r4, 36(sp)
	stw r5, 40(sp)
	stw r6, 44(sp)
	stw r7, 48(sp)

	mov r9, r7 						# upper bound for i
	# mov r9, r7   					# upper bound for j

	# start inner loop
	mov r18, r0 					# j=0

	INNER_LOOP_PLOT_LDIAG:

	bge r18, r9, EXIT_INNER_PLOT_LDIAG	# for j<5

	# plot the pixel
	movia r16,ADDR_VGA				# getting the initial device (VGA) address
	muli r19, r5, 2 				# effective x-coordinate
	muli r20, r6, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21
	# r21 = mem. location of top left pixel of (x,y)

	muli r19, r17, 2 				# effective x-coordinate
	muli r20, r18, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21				# adding the memory offset initial VGA address
	sthio r4,(r16) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */


	addi r5, r5, -1
	addi r6, r6, 1

	addi r18, r18, 1
	br INNER_LOOP_PLOT_LDIAG

	EXIT_INNER_PLOT_LDIAG:

	ldw r4, 36(sp)
	ldw r5, 40(sp)
	ldw r6, 44(sp)
	ldw r7, 48(sp)	

	ldw r23, 32(sp)
	ldw r22, 28(sp)
	ldw r21, 24(sp)
	ldw r20, 20(sp)
	ldw r19, 16(sp)
	ldw r18, 12(sp)
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)

	addi sp, sp, 52
	ret


PLOT_TANK:

	addi sp, sp, -52

	# r4 : colour
	# r5 : initial x-coordinate
	# r6 : initial y-coordinate
	# r7 : number of pixels

	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)
	stw r4, 36(sp)
	stw r5, 40(sp)
	stw r6, 44(sp)
	stw r7, 48(sp)

	mov r17, r0 					# i=0
	mov r8, r7 						# upper bound for i
	movi r9, 0xa    					# upper bound for j

	OUTER_LOOP_PLOT_TANK:

	bge r17, r8, EXIT_PLOT_TANK 				# for i<5

	# start inner loop
	mov r18, r0 					# j=0

	INNER_LOOP_PLOT_TANK:

	bge r18, r9, EXIT_INNER_PLOT_TANK	# for j<5

	# plot the pixel
	movia r16,ADDR_VGA				# getting the initial device (VGA) address
	muli r19, r5, 2 				# effective x-coordinate
	muli r20, r6, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21
	# r21 = mem. location of top left pixel of (x,y)

	muli r19, r17, 2 				# effective x-coordinate
	muli r20, r18, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21				# adding the memory offset initial VGA address
	sthio r4,(r16) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */

	addi r18, r18, 1
	br INNER_LOOP_PLOT_TANK

	EXIT_INNER_PLOT_TANK:

	addi r17, r17, 1
	br OUTER_LOOP_PLOT_TANK

	EXIT_PLOT_TANK:


	ldw r4, 36(sp)
	ldw r5, 40(sp)
	ldw r6, 44(sp)
	ldw r7, 48(sp)	

	ldw r23, 32(sp)
	ldw r22, 28(sp)
	ldw r21, 24(sp)
	ldw r20, 20(sp)
	ldw r19, 16(sp)
	ldw r18, 12(sp)
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)

	addi sp, sp, 52
	ret




PLOT_RECTANGLE:

	addi sp, sp, -52

	# r4 : colour
	# r5 : initial x-coordinate
	# r6 : initial y-coordinate
	# r7 : number of pixels

	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)
	stw r4, 36(sp)
	stw r5, 40(sp)
	stw r6, 44(sp)
	stw r7, 48(sp)

	mov r17, r0 					# i=0
	mov r8, r7 						# upper bound for i
	movi r9, 0x23    					# upper bound for j

	OUTER_LOOP_PLOT_RECT:

	bge r17, r8, EXIT_PLOT_RECT 				# for i<5

	# start inner loop
	mov r18, r0 					# j=0

	INNER_LOOP_PLOT_RECT:

	bge r18, r9, EXIT_INNER_PLOT_RECT	# for j<5

	# plot the pixel
	movia r16,ADDR_VGA				# getting the initial device (VGA) address
	muli r19, r5, 2 				# effective x-coordinate
	muli r20, r6, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21
	# r21 = mem. location of top left pixel of (x,y)

	muli r19, r17, 2 				# effective x-coordinate
	muli r20, r18, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21				# adding the memory offset initial VGA address
	sthio r4,(r16) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */

	addi r18, r18, 1
	br INNER_LOOP_PLOT_RECT

	EXIT_INNER_PLOT_RECT:

	addi r17, r17, 1
	br OUTER_LOOP_PLOT_RECT

	EXIT_PLOT_RECT:


	ldw r4, 36(sp)
	ldw r5, 40(sp)
	ldw r6, 44(sp)
	ldw r7, 48(sp)	

	ldw r23, 32(sp)
	ldw r22, 28(sp)
	ldw r21, 24(sp)
	ldw r20, 20(sp)
	ldw r19, 16(sp)
	ldw r18, 12(sp)
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)

	addi sp, sp, 52
	ret



PLOT_5x5_SQUARE:
	addi sp, sp, -52

	# r4 : colour
	# r5 : initial x-coordinate
	# r6 : initial y-coordinate
	# r7 : number of pixels

	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)
	stw r4, 36(sp)
	stw r5, 40(sp)
	stw r6, 44(sp)
	stw r7, 48(sp)

	mov r17, r0 					# i=0
	mov r8, r7 						# upper bound for i
	mov r9, r7   					# upper bound for j

	OUTER_LOOP_PLOT:

	bge r17, r8, EXIT_PLOT 				# for i<5

	# start inner loop
	mov r18, r0 					# j=0

	INNER_LOOP_PLOT:

	bge r18, r9, EXIT_INNER_PLOT	# for j<5

	# plot the pixel
	movia r16,ADDR_VGA				# getting the initial device (VGA) address
	muli r19, r5, 2 				# effective x-coordinate
	muli r20, r6, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21
	# r21 = mem. location of top left pixel of (x,y)

	muli r19, r17, 2 				# effective x-coordinate
	muli r20, r18, 1024				# effective y-coordinate
	add r21, r19, r20				# memory offset corresponding (x,y)

	add r16, r16, r21				# adding the memory offset initial VGA address
	sthio r4,(r16) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */

	addi r18, r18, 1
	br INNER_LOOP_PLOT

	EXIT_INNER_PLOT:

	addi r17, r17, 1
	br OUTER_LOOP_PLOT

	EXIT_PLOT:


	ldw r4, 36(sp)
	ldw r5, 40(sp)
	ldw r6, 44(sp)
	ldw r7, 48(sp)	

	ldw r23, 32(sp)
	ldw r22, 28(sp)
	ldw r21, 24(sp)
	ldw r20, 20(sp)
	ldw r19, 16(sp)
	ldw r18, 12(sp)
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)

	addi sp, sp, 52
	ret

PLOT_HEAD:
	# r4 : colour
	# r5 : x
	# r6 : y
	# r7 : size

	addi sp, sp, -88
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)
	stw r4, 36(sp)
	stw r5, 40(sp)
	stw r6, 44(sp)
	stw r7, 48(sp)

	stw r8, 52(sp)
	stw r9, 56(sp)
	stw r10, 60(sp)
	stw r11, 64(sp)
	stw r12, 68(sp)
	stw r13, 72(sp)
	stw r14, 76(sp)
	stw r15, 80(sp)
	
	call PLOT_5x5_SQUARE 	# PLOT_5X5_SQUARE(r4, r5, r6, r7)

	ldw r8, 52(sp)
	ldw r9, 56(sp)
	ldw r10, 60(sp)
	ldw r11, 64(sp)
	ldw r12, 68(sp)
	ldw r13, 72(sp)
	ldw r14, 76(sp)
	ldw r15, 80(sp)


	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r17, 8(sp)
	ldw r18, 12(sp)
	ldw r19, 16(sp)
	ldw r20, 20(sp)
	ldw r21, 24(sp)
	ldw r22, 28(sp)
	ldw r23, 32(sp)
	ldw r4, 36(sp)
	ldw r5, 40(sp)
	ldw r6, 44(sp)
	ldw r7, 48(sp)


	addi sp, sp, 88
	ret



# TIMER_BAR:

# 	addi sp, sp, -88
# 	stw ra, 0(sp)
# 	stw r6, 4(sp)
# 	stw r7, 8(sp)
# 	stw r8, 12(sp)
# 	stw r9, 16(sp)
# 	stw r10, 20(sp)
# 	stw r11, 24(sp)
# 	stw r12, 28(sp)
# 	stw r13, 32(sp)
# 	stw r14, 36(sp)
	
# 	stw r15, 40(sp)
# 	stw r16, 44(sp)
# 	stw r17, 48(sp)
# 	stw r18, 52(sp)
# 	stw r19, 56(sp)
# 	stw r20, 60(sp)
# 	stw r21, 64(sp)
# 	stw r22, 68(sp)
# 	stw r23, 72(sp)



# 	movui r16,0x99ff  /* black pixel */
# 	mov r6, r0
# 	movi r17, 320
# 	movi r18, 10

# 	OUTER_LOOP_TIMERBAR:

# 	bge r6, r17, EXIT_TIMERBAR

# 	# start inner loop
# 	mov r7, r0

# 	INNER_LOOP_TIMERBAR:

# 	bge r7, r18, EXIT_INNER_TIMERBAR

# 	# plot the pixel
# 	movia r19,ADDR_VGA				# getting the initial device (VGA) address
# 	muli r20, r6, 2 				# effective x-coordinate
# 	muli r21, r7, 1024				# effective y-coordinate
# 	add r22, r20, r21				# memory offset corresponding (x,y)
# 	add r19, r19, r22				# adding the memory offset initial VGA address
# 	sthio r16,(r19) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */

# 	addi r7, r7, 1
# 	br INNER_LOOP_TIMERBAR

# 	EXIT_INNER_TIMERBAR:

# 	addi r6, r6, 1
# 	br OUTER_LOOP_TIMERBAR

# 	EXIT_TIMERBAR:
	
# 	ldw r14, 36(sp)
# 	ldw r13, 32(sp)
# 	ldw r12, 28(sp)
# 	ldw r11, 24(sp)
# 	ldw r10, 20(sp)
# 	ldw r9, 16(sp)
# 	ldw r8, 12(sp)
# 	ldw r7, 8(sp)
# 	ldw r6, 4(sp)
# 	ldw ra, 0(sp)

# 	ldw r15, 40(sp)
# 	ldw r16, 44(sp)
# 	ldw r17, 48(sp)
# 	ldw r18, 52(sp)
# 	ldw r19, 56(sp)
# 	ldw r20, 60(sp)
# 	ldw r21, 64(sp)
# 	ldw r22, 68(sp)
# 	ldw r23, 72(sp)

# 	addi sp, sp, 88
# 	ret





CLEAR_SCREEN:

	addi sp, sp, -88
	stw ra, 0(sp)
	stw r6, 4(sp)
	stw r7, 8(sp)
	stw r8, 12(sp)
	stw r9, 16(sp)
	stw r10, 20(sp)
	stw r11, 24(sp)
	stw r12, 28(sp)
	stw r13, 32(sp)
	stw r14, 36(sp)

	stw r15, 40(sp)
	stw r16, 44(sp)
	stw r17, 48(sp)
	stw r18, 52(sp)
	stw r19, 56(sp)
	stw r20, 60(sp)
	stw r21, 64(sp)
	stw r22, 68(sp)
	stw r23, 72(sp)


	movui r13,0x0000  /* black pixel */
	mov r6, r0
	movi r8, 320
	movi r9, 240

	OUTER_LOOP:

	bge r6, r8, EXIT

	# start inner loop
	movi r7, 10

	INNER_LOOP:

	bge r7, r9, EXIT_INNER

# 	movi r16, 10
# 	bgt r7, r16, BLACK
# 	movui r13, 0xffff
# 	br CARRY_ON

# BLACK:
# 	movui r13, 0x0000

	# plot the pixel
	movia r14,ADDR_VGA				# getting the initial device (VGA) address
	muli r10, r6, 2 				# effective x-coordinate
	muli r11, r7, 1024				# effective y-coordinate
	add r12, r10, r11				# memory offset corresponding (x,y)
	add r14, r14, r12				# adding the memory offset initial VGA address
	sthio r13,(r14) 			/* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */

	addi r7, r7, 1
	br INNER_LOOP

	EXIT_INNER:

	addi r6, r6, 1
	br OUTER_LOOP

	EXIT:
	
	ldw r14, 36(sp)
	ldw r13, 32(sp)
	ldw r12, 28(sp)
	ldw r11, 24(sp)
	ldw r10, 20(sp)
	ldw r9, 16(sp)
	ldw r8, 12(sp)
	ldw r7, 8(sp)
	ldw r6, 4(sp)
	ldw ra, 0(sp)

	ldw r15, 40(sp)
	ldw r16, 44(sp)
	ldw r17, 48(sp)
	ldw r18, 52(sp)
	ldw r19, 56(sp)
	ldw r20, 60(sp)
	ldw r21, 64(sp)
	ldw r22, 68(sp)
	ldw r23, 72(sp)




	addi sp, sp, 88
	ret

INITIALIZE_TIMER:

	addi sp, sp, -88
	stw ra, 0(sp)
	stw r4, 4(sp)
	stw r5, 8(sp)
	stw r6, 12(sp)
	stw r7, 16(sp)
	# stw r8, 20(sp)
	# stw r9, 24(sp)
	# stw r10, 28(sp)
	# stw r11, 32(sp)
	# stw r12, 36(sp)
	# stw r13, 40(sp)
	# stw r14, 44(sp)
	# stw r15, 48(sp)
	stw r16, 52(sp)
	stw r17, 56(sp)
	stw r18, 60(sp)
	stw r19, 64(sp)
	stw r20, 68(sp)
	stw r21, 72(sp)
	stw r22, 76(sp)
	stw r23, 80(sp)

	movia r16, TIMER
	movui r8, %lo(PERIOD)
	movui r9, %hi(PERIOD)
	stwio r8, 8(r16)          		# lo period
	stwio r9, 12(r16)				# hi period

	stwio r0, 0(r16)					# reset timer

	movui r8, 4 					# doesn't restart after timing out
	stwio r8, 4(r16)             

POLL_TIMER:

	ldwio r9, 0(r16)
	andi r9, r9, 0X1

	beq r9, r0, POLL_TIMER



	ldw ra, 0(sp)
	ldw r4, 4(sp)
	ldw r5, 8(sp)
	ldw r6, 12(sp)
	ldw r7, 16(sp)
	# ldw r8, 20(sp)
	# ldw r9, 24(sp)
	# ldw r10, 28(sp)
	# ldw r11, 32(sp)
	# ldw r12, 36(sp)
	# ldw r13, 40(sp)
	# ldw r14, 44(sp)
	# ldw r15, 48(sp)
	ldw r16, 52(sp)
	ldw r17, 56(sp)
	ldw r18, 60(sp)
	ldw r19, 64(sp)
	ldw r20, 68(sp)
	ldw r21, 72(sp)
	ldw r22, 76(sp)
	ldw r23, 80(sp)

	addi sp, sp, 88

	ret


GET_PIXEL_ADDRESS:

# input
	# r4 : x-coordinate
	# r5 : y-coordinate

# output
	# r2 : VGA memory location of (x,y)

	addi sp, sp, -40
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)

	mov r16, r4
	mov r17, r5
	movia r18, ADDR_VGA
	muli r19, r16, 2
	muli r20, r17, 1024
	add r21, r19, r20				# r21 : holds the memory offset
	add r16, r16, r21				# r16 : holds the actual VGA memory location

	mov r2, r16

	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r17, 8(sp)
	ldw r18, 12(sp)
	ldw r19, 16(sp)
	ldw r20, 20(sp)
	ldw r21, 24(sp)
	addi sp, sp, 40
	ret


COLLISION:

	addi sp, sp, -40
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)

	movia r4,RED_LEDS  				# load address of LEDs
	movui r5, 1;
	stwio r5, 0(r4)


	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r17, 8(sp)
	ldw r18, 12(sp)
	ldw r19, 16(sp)
	ldw r20, 20(sp)
	ldw r21, 24(sp)
	ldw r22, 28(sp)
	ldw r23, 32(sp)

	addi sp, sp, 40

	ret

END:
	addi sp, sp, 40
	br ENDD
	
ENDD:
	br END





