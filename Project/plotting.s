.include "nios_macros.s"

.equ TOP_OF_MEMORY, 0X1000
.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000
.equ TIMER, 0x10002000

.text

.global _start

_start:

	addi sp, sp, -40

	movia sp, TOP_OF_MEMORY		# initializing address for stack pointer

	movui r4,0x0000  		# White pixel
	movi  r5, 0x41   		# ASCII for 'A'

	call CLEAR_SCREEN		# flush the background

	movi r5, 10 				# r5(x-coordinate) : second paramter to function plot_5x5_square
	movi r6, 20 				# r6(y-coordinate) : third parameter to function plot_5x5_square
	movi r7, 100

LOOP1:
	bge r5, r7, EXIT_LOOP1

	movui r4, 0xffff		# r4(colour) : first parameter
	stw r8, 0(sp)
	stw r9, 4(sp)
	call PLOT_5x5_SQUARE
	ldw r8, 0(sp)
	ldw r9, 4(sp)



	addi r5, r5, 1
	br LOOP1

EXIT_LOOP1:

	# addi r3, r3, 132
	# # # sthio r4,1032(r2) /* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */
	# stbio r5,(r3)	 /* character (4,1) is x + y*128 so (4 + 128 = 132) */


	addi sp, sp, 40

br END



PLOT_5x5_SQUARE:
	addi sp, sp, -40

	# r4 : colour
	# r5 : initial x-coordinate
	# r6 : initial y-coordinate

	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)
	stw r20, 20(sp)
	stw r21, 24(sp)
	stw r22, 28(sp)
	stw r23, 32(sp)

	mov r17, r0 					# i=0
	movi r8, 5 						# upper bound for i
	movi r9, 5   					# upper bound for j

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
	
	ldw r23, 32(sp)
	ldw r22, 28(sp)
	ldw r21, 24(sp)
	ldw r20, 20(sp)
	ldw r19, 16(sp)
	ldw r18, 12(sp)
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)

	addi sp, sp, 40
	ret




CLEAR_SCREEN:

	addi sp, sp, -40
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


	movui r13,0x0000  /* White pixel */
	mov r6, r0
	movi r8, 320
	movi r9, 240

	OUTER_LOOP:

	bge r6, r8, EXIT

	# start inner loop
	mov r7, r0

	INNER_LOOP:

	bge r7, r9, EXIT_INNER

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

	addi sp, sp, 40
	ret

# INITIALIZE_TIMER:
# 	movia r7, TIMER
# 	movui r2, 10000
# 	stwio r2, 8(r7)          		# lo period
# 	stwio r0, 12(r7)				# hi period

# 	movui r2, 4
# 	stwio r2, 4(r7)             

# POLL_TIMER:

# 	ldwio r15, 0(r7)
# 	bne r16, r15, POLL_TIMER
#   	ret



END:
	br END





