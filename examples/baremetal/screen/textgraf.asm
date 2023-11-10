; CpS 230 Example Program: DOSBox Text Mode framebuffer demo
; (c) 2016, BJU
;------------------------------------------------------------
bits 16

org	0x100

CpR	equ	80	; 80 characters per row
RpS	equ	25	; 25 rows per screen
BpC	equ	2	; 2 bytes per character


CHARS	equ	4	; number of characters in the message "BJU!"

; Compute starting offset to store "BJU!" in VRAM centered on row 12
MESSAGE_START	equ	(12 * CpR * BpC) + (((CpR - (CHARS / 2)) / 2) * BpC)

section .text
start:
	mov	ax, 0xb800
	mov	es, ax
	
	; Clear screen to black (copy 80*25*2 byte of ZERO to the framebuffer)
	mov	al, 0
	mov	cx, CpR*RpS*BpC
	mov	di, 0
	rep	stosb
	
	; "BJU!" in bright blue on white, center of screen, in text mode
	mov	di, MESSAGE_START
	mov	ah, 0x1F	; background = 1 (blue), foreground = 15 (bright white)
	mov	al, 'B'
	stosw
	mov	al, 'J'
	stosw
	mov	al, 'U'
	stosw
	mov	al, '!'
	stosw
	
	; Wait for keyboard input (echo)
	mov	ah, 0x01
	int	0x21
	
	; quit-to-DOS
	mov	ah, 0x4c
	int	0x21
