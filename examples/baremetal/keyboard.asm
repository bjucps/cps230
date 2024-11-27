; CpS 230 Demo Program: Keyboard Interrupt Handler
;-------------------------------------------------
bits 16

org 0x100

KEYBOARD_INT_OFFSET	equ	9*4
KEYBOARD_INT_SEGMENT	equ	KEYBOARD_INT_OFFSET+2

SCAN_ESC	equ	1

section .text
start:
	; ES = 0000 (for manipulating IVT)
	xor	ax, ax		; AX = 0000
	mov	es, ax
	
	; Install custom keyboard interrupt handler (vector 9)
	cli
	mov	ax, [es:KEYBOARD_INT_OFFSET]
	mov	[kbisr_chain_offset], ax
	mov	ax, [es:KEYBOARD_INT_SEGMENT]
	mov	[kbisr_chain_segment], ax
	mov	[es:KEYBOARD_INT_SEGMENT], cs
	mov	word [es:KEYBOARD_INT_OFFSET], keyboard_isr
	sti
	
	; Prompt user to press ESC
	mov	ah, 9
	mov	dx, prompt_msg
	int	0x21
	
	; Spin until kbarray[SCAN_ESC] is non-zero
.wait_for_keydown:
	test	byte [kbarray + SCAN_ESC], 1
	jz	.wait_for_keydown
	
	; Now prompt user to release ESC
	mov	ah, 9
	mov	dx, key_down_msg
	int	0x21
	
	; Spin until kbarray[SCAN_ESC] is zero
.wait_for_keyup:
	test	byte [kbarray + SCAN_ESC], 1
	jnz	.wait_for_keyup
	
	; Now say goodbye
	mov	ah, 9
	mov	dx, key_up_msg
	int	0x21
	
	; And uninstall the interrupt handler, restoring the original BIOS handler
	cli
	mov	ax, [kbisr_chain_offset]
	mov	[es:KEYBOARD_INT_OFFSET], ax
	mov	ax, [kbisr_chain_segment]
	mov	[es:KEYBOARD_INT_SEGMENT], ax
	sti

	; Quit to DOS
	mov	ah, 0x4c
	int	0x21

; Very brain-dead keyboard interrupt handler (does not properly handle ANY extended key sequences)
; Sets kbarray[SCAN_CODE] to 0xff on keypress, and to 0x00 on keyrelease
; (where SCAN_CODE is the numeric scan code [NOT ASCII CODE!] of the key in question)
; (does NOT chain to original handler; handles its own interrupt acknowledgements)
keyboard_isr:
	push	ax
	push	bx
	
	in	al, 0x60	; Read scancode from Intel 8042 keyboard controller (https://stanislavs.org/helppc/8042.html)
	
	mov	bl, al
	and	bx, 0x7f	; Keep only bottom 7 bits (BX=index into kbarray)
	sar	al, 7		; Shift top bit to bottom of AL (AL == 0 or AL == 0xff now)
	not	al		; AL = 0 on release, AL = 0xff on press
	mov	[cs:kbarray + bx], al
	
	mov	al, 0x20
	out	0x20, al	; Acknowledge interrupt to Intel 8259 PIC (https://stanislavs.org/helppc/8259.html)
	
	pop	bx
	pop	ax
	iret

section .data
kbarray			times	128	db	0
kbisr_chain_addr:
kbisr_chain_offset	dw	0
kbisr_chain_segment	dw	0

prompt_msg	db	"Press ESC to quit...", 10, 13, '$'
key_down_msg	db	"Now release it...", 10, 13, '$'
key_up_msg	db	"All done!", 10, 13, 10, 13, '$'

