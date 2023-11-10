; CpS 230 Demo Program: Annoying PC Speaker Music
;-------------------------------------------------
; Origin story: the note/delay/display data for
; this demo originates with the legendary/notorious
; J_Bond2* test program for the old CpS 310 Sim86
; project (an 8086 simulator). Getting J_Bond2 to
; run on one's simulator was a rite of passage--
; it usually indicated that one was about 90% of
; the way to an A-level simulator working. With
; the move to an ARM simulator in 310 and the general
; demise of decent PC speaker capabilities, J_Bond2
; has languished in obsolescence. Until now...
;
; * - the existence of a J_Bond1 or plain old J_Bond
;     has never been confirmed or denied...
;
; OBLIGATORY DISCLAIMER:
; The melody played by this program may or may not
; be derived from the popular signature theme song
; of a series of implausible (and often objectionable)
; spy thriller films which shall not be named here.
; In any case, this test program does not constitute
; any form of endorsement, official or unofficial, of
; any films which may or may not have inspired the
; students who wrote the original version many
; years ago...
;-------------------------------------------------
bits 16

org 0x100

CR		equ	13
LF		equ	10
SPEAKER_PORT	equ	0x61
PIT_CTL		equ	0x43
PIT_PROG	equ	0xb6	; 0b10110110: 10 (chan 2) 11 (read LSB/MSB) 011 (mode 3) 0 (binary)
PIT_CHAN2	equ	0x42

; Musical note constants (0x1234dd / freq)
C2	equ	20933
Csh2	equ	19886
D2	equ	18643
Dsh2 	equ	17809
Efl2	equ	17809
E2	equ	16805
F2 	equ	15700
Esh2	equ	15700
Fsh2	equ	14915
G2	equ	14037
Gsh2	equ	13258
A2	equ	12560
Ash2 	equ	11814
Bfl2	equ	11814
B2	equ	11151
C3	equ	10559
Csh3	equ	9943
D3	equ	9395
Dsh3 	equ	8838
Efl3	equ	8838
E3	equ	8344
F3 	equ	7902
Esh3	equ	7902
Fsh3	equ	7457
G3	equ	7019
Gsh3	equ	6629
A3	equ	6280
Ash3 	equ	5907
Bfl3	equ	5907
B3	equ	5576
C4	equ	5280
Csh4	equ	4972
D4	equ	4698
Dsh4 	equ	4436
Efl4	equ	4436
E4	equ	4187
F4 	equ	3951
Esh4	equ	3951
Fsh4	equ	3729
G4	equ	3520
Gsh4	equ	3314
A4	equ	3132
Ash4 	equ	2953
Bfl4	equ	2953
B4	equ	2788
C5	equ	2634
Csh5	equ	2486
D5	equ	2349
Dsh5 	equ	2256
Efl5	equ	2256
E5	equ	2090
F5 	equ	1972
Esh5	equ	1972
Fsh5	equ	1861
G5	equ	1757
Gsh5	equ	1660
A5	equ	1566
Ash5 	equ	1479
Bfl5	equ	1479
B5	equ	1396
C6	equ	1317
Csh6	equ	1243
D6	equ	1173
Dsh6 	equ	1108
Efl6	equ	1108
E6	equ	1046
F6 	equ	987
Esh6	equ	987
Fsh6	equ	931
G6	equ	879
Gsh6	equ	830
A6	equ	783
Ash6 	equ	739
Bfl6	equ	739
B6	equ	698

section .text
start:
	; Start at the beginning
	mov	si, notes
	mov	di, durations
	mov	bp, credits

	; Capture initial speaker state
	in	al, SPEAKER_PORT
	and	al, 0xfc
	mov	[portval], al
	
.next:
	cmp	si, end_of_notes
	jz	.end_of_song

	mov	bx, [si]
	add	si, 2
	
	; Is this a "rest" (freq 0)?
	test	bx, bx
	jnz	.set_freq
	mov	al, [portval]
	out	SPEAKER_PORT, al
	jmp	.do_delay
.set_freq:
	; Program PIT channel 2 to generate a given note
	mov	al, PIT_PROG
	out	PIT_CTL, al
	mov	al, bl
	out	PIT_CHAN2, al
	mov	al, bh
	out	PIT_CHAN2, al
	
	; Turn on speaker (driven by PIT channel 2)
	mov	al, [portval]
	or	al, 3
	out	SPEAKER_PORT, al
.do_delay:
	; Print next 2 characters in splashy "credits" sequence
	mov	ah, 0x0e
	xor	bx, bx
	mov	al, [bp]
	inc	bp
	int	0x10
	mov	al, [bp]
	inc	bp
	int	0x10
	
	; Delay
	mov	cx, [di]
	add	di, 2
	jcxz	.no_delay
	call	delay

.no_delay:
	; Turn off speaker
	mov	al, [portval]
	out	SPEAKER_PORT, al
	
	; Tiny delay (to give space to notes)
	mov	cx, 1
	call	delay
	
	; Next! (only if no key was pressed)
	mov	ah, 1
	int	0x16
	jz	.next

	; A key was pressed...
	mov	ah, 0
	int	0x16

.end_of_song:
	; Turn off the speaker
	mov	al, [portval]
	out	0x61, al
	
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

notes:
	dw B4, B4, 0, B3, B4, B4, 0, B3, B4, B4, B4, B4, B4, B3, C4
	dw Csh4, C4, B3, C4, Csh4, C4
	dw E4, Fsh4, Fsh4, Fsh4, Fsh4, E4, E4, E4
	dw E4, G4, G4, G4, G4, Fsh4, Fsh4, Fsh4
	dw E4, Fsh4, Fsh4, Fsh4, Fsh4, E4, E4, E4
	dw E4, G4, G4, G4, G4, Fsh4, Fsh4, Fsh4
	dw E4, Fsh4, Fsh4, Fsh4, Fsh4, E4, E4, E4
	dw E4, G4, G4, G4, G4, Fsh4, Fsh4, Fsh4
	dw Dsh5, D5, 0, B4, A4, B4 
	dw E4, Fsh4, Fsh4, Fsh4, Fsh4, E4, E4, E4
	dw E4, G4, G4, G4, G4, Fsh4, Fsh4, Fsh4
	dw E4, Fsh4, Fsh4, Fsh4, Fsh4, E4, E4, E4
	dw E4, G4, G4, G4, G4, Fsh4, Fsh4, Fsh4   
	dw E4, G4, Dsh5, D5, G4
	dw Ash4, B4, 0, 0
	dw G4, A4, G4, Fsh4, B3, E4, Csh4
end_of_notes:

durations:
	dw 4, 4, 0, 10, 4, 4, 0, 10, 2, 4, 2, 4, 4, 16, 16
	dw 16, 16, 16, 16, 16, 16
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 16, 0, 4, 4, 32
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 8, 4, 10, 4
	dw 4, 16, 0, 0
	dw 4, 2, 2, 10, 4, 4, 32
	
credits:
	db "    ******   ******   *******  =========================",CR,LF
	db "   *******  *******  *******  ============",CR,LF
	db "  **   **  **   **  *    **   (  |",CR,LF
	db " **   **  **   **       **  ____/",CR,LF
	db "*******  *******       **",CR,LF
	db "******   ******       **    James Bond", CR, LF
	db "                        "