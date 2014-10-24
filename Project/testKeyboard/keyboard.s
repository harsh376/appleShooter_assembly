.equ PS2_KEYBOARD_DATA, 0x10000100
.equ PS2_KEYBOARD_CONTROL, 0x10000104
.equ RED_LEDS, 0x10000000
.equ GREEN_LEDS, 0x10000010
.equ ADDR_7SEG1, 0x10000020

.section .exceptions, "ax"

IHANDLER:
	rdctl et, ctl4				# read ipending : ctl4
	andi et, et, 0x80			# 0x80 = 0000 0000 1000 0000
	movi r20, 0x1 					
	mov r17, r0
	beq et, r0, EXIT_HANDLER	# checking if IRQ 7 is pending (i.e ps/2)


KEYBOARD:
	ldwio r12, 0(r8)			# loading the data
	movi r13, 0xff					
	and r12, r12, r13			# bits [7:0] from data register

UP_KEY:
	cmpeqi r16, r12, 0x75
	beq r16, r0, DOWN_KEY
	addi r23, r23, 1
	movia r17, RED_LEDS
	# movui r18, 1
	stwio r23, 0(r17)
	br EXIT_HANDLER

DOWN_KEY:
	cmpeqi r16, r12, 0x72
	beq r16, r0, LEFT_KEY
	addi r23, r23, -1
	movia r17, RED_LEDS
	# movui r18, 1
	stwio r23, 0(r17)
	br EXIT_HANDLER


LEFT_KEY:
	cmpeqi r16, r12, 0x6b
	beq r16, r0, RIGHT_KEY
	addi r21, r21, -1
	movia r17, GREEN_LEDS
	# movui r18, 1
	stwio r21, 0(r17)
	br EXIT_HANDLER

RIGHT_KEY:
	cmpeqi r16, r12, 0x74
	beq r16, r0, ENTER
	addi r21, r21, 1
	movia r17, GREEN_LEDS
	# movui r18, 1
	stwio r21, 0(r17)
	br EXIT_HANDLER


ENTER:
	cmpeqi r16, r12, 0x5a
	beq r16, r0, EXIT_HANDLER
	movia r17, GREEN_LEDS
	movui r22, 1
	stwio r22, 0(r17)
	br EXIT_HANDLER


EXIT_HANDLER:
	subi ea, ea, 4
	eret



.section .text

.global main

main:
	movia r8, PS2_KEYBOARD_DATA
	movia r9, PS2_KEYBOARD_CONTROL
	

	movi r23, 0 			# up-down counter
	movi r22, 0 			# enter
	movi r21, 0  			# left-right counter

	ldwio r10, 0(r9)		# reading from 4(keyboard) control bits
	movi r11, 0x1
	or r10, r11, r10
	stwio r10, 0(r9)		# configure device
	movi r11, 0x80
	wrctl ctl3, r11			# enable IRQ 7 : ctl3
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
	movia r2,ADDR_7SEG1
	movia r3,0x00000008   	# /* bits 0000110 will activate segments 1 and 2 */
	stwio r3,0(r2)        	# /* Write to 7-seg display */


END:
	mov r11, r0
	wrctl ctl0, r11			# enable external interrupts : ctl0 / PIE
	br END
# keyboard:
# 	ldwio r12, 0(r8)
# 	movi r13, 0xff
# 	and r12, r12, r13

# UP_KEY:
# 	cmpeqi r16, r12, 0x1d
# 	beq r16, r0, DOWN_KEY
# 	movi r19, 0x71
# 	stwio r19, 0(r18)
# 	br exit_handler

