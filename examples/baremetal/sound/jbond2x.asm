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
; has languished in obsolescence. Until now!
;
; This _extended_ (hence "jbond2x") version of the
; classic J_Bond2 demo uses a hooked IRQ0/INT8
; timer interrupt to provide actually CPU-speed-
; independent music tempo and (although this program
; doesn't really show it off at all) playing music
; in the "background" while the "main program"
; keeps on doing cool stuff (this program just keeps
; checking for the "done" flag and/or a key press).
; Of note is the fact that we reprogram PIT channel 0
; to give us INT8 interrupts at 100Hz, not the usual
; 18.2Hz, since 100Hz gives us much finer granularity
; of timing events.  We follow the approach sketched
; out in the PC-GPE "PIT" article to keep invoking the
; original INT8 handler at the usual 18.2Hz frequency
; in order to keep the system clock (and any chained
; INT8 hook handlers) firing away at the usual rate.
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
SPEAKER_PORT	equ	0x61			; I/O port for speaker control
PIT_CTL		equ	0x43			; PIT control data port; used to pass one of the programming patterns (PIT_PROG0, PIT_PROG2) into the PIT
PIT_PROG0	equ	0x34			; 0b00110100: 00 (chan 0) 11 (read LSB/MSB; full 16-bit count) 010 (mode 2; divide-by-N rate generator) 0 (binary, not BCD)
PIT_CHAN0	equ	0x40			; PIT channel 0 data port; used to reprogram the rate of the IRQ0/INT8 timer interrupt [i.e., set freq counter]
PIT_PROG2	equ	0xb6			; 0b10110110: 10 (chan 2) 11 (read LSB/MSB; full 16-bit count) 011 (mode 3; square-wave generator) 0 (binary, not BCD)
PIT_CHAN2	equ	0x42			; PIT channel 2 data port; used to control the timer than drives the PC speaker [i.e., set freq counter]
PIC_ACK_MSG	equ	0x20			; write PIC_ACK_MSG to port PIC_ACK_PORT to perform "general" interrupt ack when needed
PIC_ACK_PORT	equ	0x20

CLOCK_CTR	equ	0x1234dd / 100		; PIT-freq-quotient we use to get IRQ0 on a 100Hz frequency (also, we use this to count up normal 18.2Hz ticks on which to keep the BIOS clock up to date)

IRQ0_OFF_SLOT	equ	(8 * 4)			; IRQ0 -> INT 8 -> slot 8 in IVT (each slot is 4 bytes; OFFSET_LOW, OFFSET_HIGH, SEGMENT_LOW, SEGMENT_HIGH)
IRQ0_SEG_SLOT	equ	IRQ0_OFF_SLOT + 2

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
	; Capture initial speaker state
	in	al, SPEAKER_PORT
	and	al, 0xfc
	mov	[portval], al
	
	; install alternate int8 handler
	xor	ax, ax
	mov	es, ax
	cli
	mov	ax, [es:IRQ0_OFF_SLOT]
	mov	[old_int8off], ax
	mov	ax, [es:IRQ0_SEG_SLOT]
	mov	[old_int8seg], ax
	mov	word [es:IRQ0_OFF_SLOT], t_isr
	mov	[es:IRQ0_SEG_SLOT], cs

	; before re-enabling interrupts, reprogram PIT channel 0 to our modified rate (100Hz)
	mov	al, PIT_PROG0
	out	PIT_CTL, al
	mov	dx, CLOCK_CTR
	mov	al, dl
	out	PIT_CHAN0, al
	mov	al, dh
	out	PIT_CHAN0, al
	sti

	; check for key strokes (early quit) in a loop while waiting for [done] to be set
.spin:	hlt				; wait for interrupt (keyboard, timer, whatever)
	cmp	byte [done], 0		; is the song marked done?
	jne	.brk			; then quit
	mov	ah, 0x01		; is a key pressed?
	int	0x16
	jz	.spin			; NO; so keep spinning
	mov	ah, 0			; consume key
	int	0x16

.brk:	; Uninstall timer interrupt; revert PIT channel 0 to the 18.2Hz rate used by the DOS/BIOS clock
	cli
	mov	ax, [old_int8off]
	mov	[es:IRQ0_OFF_SLOT], ax
	mov	ax, [old_int8seg]
	mov	[es:IRQ0_SEG_SLOT], ax
	mov	al, PIT_PROG0
	out	PIT_CTL, al
	xor	al, al
	out	PIT_CHAN0, al		; writing 0x0000 as a counter gives the MAX interval
	out	PIT_CHAN0, al
	sti

	; Turn off the speaker
	mov	al, [portval]
	out	SPEAKER_PORT, al
	
	; Quit to DOS
	mov	ah, 0x4c
	int	0x21


section .data
portval		db	0
pit_ticks	dw	0		; add CLOCK_CTR to this each IRQ0 interrupt (each time it overflows, chain-call the original BIOS INT8 handler)
old_int8off	dw	0		; saved INT8 int handler (for chaining)
old_int8seg	dw	0
index		dw	0		; "index pointer" to our current location in the song (advances by 2 each event forward)
ttl		dw	0		; count-down to next index event (decrements by one each IRQ0)
done		db	0

t_isr:	push	ax				; save AX
	cmp	byte [cs:done], 0		; are we done?
	jne	.clk				; if so, just keep the clock synced

	mov	ax, [cs:ttl]			; find out ticks-to-next-event
	cmp	ax, 0
	jle	.go				; if TTL=0, go process the next event
	dec	ax				; otherwise, decrement TTL and jump to the clock-sync logic
	mov	[cs:ttl], ax
	jmp	.clk	

.go:	push	si
	push	bx
	mov	si, [cs:index]			; get the [index] variable into SI (after saving SI)

	; update speaker state
	lea	bx, [notes + si]		; get address of "next note"
	cmp	bx, end_of_notes		; are we done?
	jb	.gogo
	mov	al, [cs:portval]		; kill the speaker
	out	SPEAKER_PORT, al
	mov	byte [cs:done], 1		; MARK US DONE
	pop	bx
	pop	si
	jmp	.clk				; and go to the clock
	

.gogo:	mov	bx, [cs:notes + si]		; get the next note freq (into BX)
	cmp	bx, 0				; are we turning the speaker OFF?
	je	.rest
	mov	al, PIT_PROG2			; no, time to CHANGE FREQ for this new note
	out	PIT_CTL, al
	mov	al, bl
	out	PIT_CHAN2, al
	mov	al, bh
	out	PIT_CHAN2, al
	mov	al, [cs:portval]		; turn on speaker
	or	al, 3
	out	SPEAKER_PORT, al
	jmp	.txt

.rest:	mov	al, [cs:portval]		; turn it off, for the rest
	out	SPEAKER_PORT, al

	; handle text output
.txt:	xor	bx, bx
	mov	ah, 0x0e
	mov	al, [cs:credits + si]
	int	0x10
	mov	al, [cs:credits + si + 1]
	int	0x10

	; set the next ttl
.ttl:	mov	ax, [cs:durations + si]		; read the current duration (we want 5*duration 100Hz ticks of delay)
	mov	bx, ax
	shl	ax, 1
	shl	ax, 1
	add	ax, bx
	mov	[cs:ttl], ax

	; finish
	inc	si				; [index] += 2 (and restore SI)
	inc	si	
	mov	[cs:index], si
	pop	bx
	pop	si

	; keep the BIOS clock sync'd	
.clk:	add	word [cs:pit_ticks], CLOCK_CTR	; update ticks by our divider-interval
	jnc	.self				; if there was no carry-out, we aren't ready for chaining yet...
	pop	ax				; (restore AX)
	jmp	far [cs:old_int8off]		; ...otherwise, chain to old INT8 handler

.self:	mov	al, PIC_ACK_MSG			; ack the PIC ourselves
	out	PIC_ACK_PORT, al
	pop	ax				; restore AX; return from interrupt
	iret


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
