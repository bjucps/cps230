; CpS 230 Demo Program: PC Speaker Code for DOSBox
;-------------------------------------------------
bits 16

org 0x100

SPEAKER_PORT	equ	0x61
PIT_CTL		equ	0x43
PIT_PROG	equ	0xb6	; 0b10110110: 10 (chan 2) 11 (read LSB/MSB) 011 (mode 3) 0 (binary)
PIT_CHAN2	equ	0x42
PIT_FREQ	equ	0x1234DD

section .text
start:
	; Capture initial speaker state
	in	al, SPEAKER_PORT
	and	al, 0xfc
	mov	[portval], al
	
	; Program PIT channel 2 to count at (0x1234DD / 440) [to generate A 440]
	; [note that this division is performed at assembly-time by NASM]
	mov	bx, (PIT_FREQ / 440)
	mov	al, PIT_PROG
	out	PIT_CTL, al
	mov	al, bl
	out	PIT_CHAN2, al
	mov	al, bh
	out	PIT_CHAN2, al
	
	; Turn on the speaker
	mov	al, [portval]
	or	al, 3
	out	SPEAKER_PORT, al
	
	; Delay for about 1 second
	mov	cx, 18
	call	delay
	
	; Turn off the speaker
	mov	al, [portval]
	out	SPEAKER_PORT, al
	
	; Quit to DOS
	mov	ah, 0x4c
	int	0x21


; Delay for CX clock-ticks (18.2 ticks per second)
; Receives: tick count in CX (must be > 0)
; Returns: nothing
; Clobbers: CX
delay:
	push	ax
	push	bx
	push	dx
	
	xor	ah, ah
.reps:
	push	cx		; Save CX (because INT 0x1A trashes it)
	int	0x1a		; Get ticks-since-boot in cx:dx
	mov	bx, dx		; Save the lower WORD of the tick count
.spin:
	int	0x1a
	cmp	bx, dx
	jz	.spin		; Spin until that WORD changes (i.e., until the current tick expires)
	
	pop	cx		; Restore CX...
	loop	.reps		; ...so we can use that to count loops

	pop	dx
	pop	bx
	pop	ax
	ret

section .data
portval	db	0
