; CpS 230 Example Program: DOSBox basic VGA framebuffer demo
; (c) 2016, BJU
;------------------------------------------------------------
bits 16

org 	0x100

PpR	equ	320	; 320 pixels per row/scanline
RpS	equ	200	; 200 rows per screen/framebuffer

CENTER	equ	((RpS / 2) * PpR) + (PpR / 2)

section .text
start:
	; Set VGA graphics mode (320x200x8-bit)
	mov	ah, 0
	mov	al, 0x13
	int	0x10

	; Set up ES to be our framebuffer segment
	mov	ax, 0xA000
	mov	es, ax
	
	; Clear screen to black (copy 320*200 byte of ZERO to the framebuffer)
	mov	al, 0
	mov	cx, PpR*RpS
	mov	di, 0
	rep	stosb
	
	; Turn on a single bright-white pixel in the middle of the screen
	mov	byte [es:CENTER], 31
	
	; Read a key, no echo-to-screen (use BIOS routines instead of DOS)
	mov	ah, 0x10
	int	0x16
	
	; Reprogram color 31 to be bright red
	mov	dx, 0x3c8
	mov	al, 31
	out	dx, al
	mov	dx, 0x3c9
	mov	al, 63
	out	dx, al		; R=63
	mov	al, 0
	out	dx, al		; G=0
	out	dx, al		; B=0
	
	; Read a key, no echo-to-screen (use BIOS routines instead of DOS)
	mov	ah, 0x10
	int	0x16
	
	; Return to text mode
	mov	ah, 0
	mov	al, 3
	int	0x10
	
	; Quit-to-DOS
	mov	ah, 0x4c
	int	0x21
