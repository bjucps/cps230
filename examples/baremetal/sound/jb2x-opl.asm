; CpS 230 Demo Program: Annoying PC Speaker Music
;-------------------------------------------------
; Adaptation of the classic J_Bond2 music demo to
; use the AdLib/OPL2 music synthesizer card/chip.
; (Actually modifies the IRQ0/INT8 timer interrupt
; driven variant, jbond2x...)
;-------------------------------------------------
bits 16

org 0x100

CR		equ	13
LF		equ	10
PIT_CTL		equ	0x43			; PIT control data port; used to pass PIT_PROG0 to the PIT control register so we can reprogram the IRQ0 timer
PIT_PROG0	equ	0x34			; 0b00110100: 00 (chan 0) 11 (read LSB/MSB; full 16-bit count) 010 (mode 2; divide-by-N rate generator) 0 (binary, not BCD)
PIT_CHAN0	equ	0x40			; PIT channel 0 data port; used to reprogram the rate of the IRQ0/INT8 timer interrupt [i.e., set freq counter]
PIC_ACK_MSG	equ	0x20			; write PIC_ACK_MSG to port PIC_ACK_PORT to perform "general" interrupt ack when needed
PIC_ACK_PORT	equ	0x20
ADLIB_APORT	equ	0x0388			; Adlib (OPL2) synthesizer chip address register port
ADLIB_DPORT	equ	0x0389			; OPL2 data register port

CLOCK_CTR	equ	0x1234dd / 100		; PIT-freq-quotient we use to get IRQ0 on a 100Hz frequency (also, we use this to count up normal 18.2Hz ticks on which to keep the BIOS clock up to date)

IRQ0_OFF_SLOT	equ	(8 * 4)			; IRQ0 -> INT 8 -> slot 8 in IVT (each slot is 4 bytes; OFFSET_LOW, OFFSET_HIGH, SEGMENT_LOW, SEGMENT_HIGH)
IRQ0_SEG_SLOT	equ	IRQ0_OFF_SLOT + 2

; Musical note constants (combining 3-bit octave selector and 10-bit OPL2-specific "freq-num")
C2	equ	(1 << 10) | 0x2ae	; octave 1, fnum 0x2ae
Csh2	equ	(2 << 10) | 0x16b	; octave 2, f-num 0x16b
D2	equ	(2 << 10) | 0x181
Dsh2 	equ	(2 << 10) | 0x198
Efl2	equ	(2 << 10) | 0x198	; alias
E2	equ	(2 << 10) | 0x1b0
F2 	equ	(2 << 10) | 0x1ca
Esh2	equ	(2 << 10) | 0x1ca	; alias
Fsh2	equ	(2 << 10) | 0x1e5
G2	equ	(2 << 10) | 0x202
Gsh2	equ	(2 << 10) | 0x220
A2	equ	(2 << 10) | 0x241
Ash2 	equ	(2 << 10) | 0x263
Bfl2	equ	(2 << 10) | 0x263	; alias
B2	equ	(2 << 10) | 0x287
C3	equ	(2 << 10) | 0x2ae
Csh3	equ	(3 << 10) | 0x16b	; octave 3, f-num 0x16b
D3	equ	(3 << 10) | 0x181
Dsh3 	equ	(3 << 10) | 0x198
Efl3	equ	(3 << 10) | 0x198	; alias
E3	equ	(3 << 10) | 0x1b0
F3 	equ	(3 << 10) | 0x1ca
Esh3	equ	(3 << 10) | 0x1ca	; alias
Fsh3	equ	(3 << 10) | 0x1e5
G3	equ	(3 << 10) | 0x202
Gsh3	equ	(3 << 10) | 0x220
A3	equ	(3 << 10) | 0x241
Ash3 	equ	(3 << 10) | 0x263
Bfl3	equ	(3 << 10) | 0x263	; alias
B3	equ	(3 << 10) | 0x287
C4	equ	(3 << 10) | 0x2ae
Csh4	equ	(4 << 10) | 0x16b	; octave 4, f-num 0x16b
D4	equ	(4 << 10) | 0x181
Dsh4 	equ	(4 << 10) | 0x198
Efl4	equ	(4 << 10) | 0x198	; alias
E4	equ	(4 << 10) | 0x1b0
F4 	equ	(4 << 10) | 0x1ca
Esh4	equ	(4 << 10) | 0x1ca	; alias
Fsh4	equ	(4 << 10) | 0x1e5
G4	equ	(4 << 10) | 0x202
Gsh4	equ	(4 << 10) | 0x220
A4	equ	(4 << 10) | 0x241
Ash4 	equ	(4 << 10) | 0x263
Bfl4	equ	(4 << 10) | 0x263	; alias
B4	equ	(4 << 10) | 0x287
C5	equ	(4 << 10) | 0x2ae
Csh5	equ	(5 << 10) | 0x16b	; octave 5, f-num 0x16b
D5	equ	(5 << 10) | 0x181
Dsh5 	equ	(5 << 10) | 0x198
Efl5	equ	(5 << 10) | 0x198	; alias
E5	equ	(5 << 10) | 0x1b0
F5 	equ	(5 << 10) | 0x1ca
Esh5	equ	(5 << 10) | 0x1ca	; alias
Fsh5	equ	(5 << 10) | 0x1e5
G5	equ	(5 << 10) | 0x202
Gsh5	equ	(5 << 10) | 0x220
A5	equ	(5 << 10) | 0x241
Ash5 	equ	(5 << 10) | 0x263
Bfl5	equ	(5 << 10) | 0x263	; alias
B5	equ	(5 << 10) | 0x287
C6	equ	(5 << 10) | 0x2ae
Csh6	equ	(6 << 10) | 0x16b	; octave 6, f-num 0x16b
D6	equ	(6 << 10) | 0x181
Dsh6 	equ	(6 << 10) | 0x198
Efl6	equ	(6 << 10) | 0x198	; alias
E6	equ	(6 << 10) | 0x1b0
F6 	equ	(6 << 10) | 0x1ca
Esh6	equ	(6 << 10) | 0x1ca	; alias
Fsh6	equ	(6 << 10) | 0x1e5
G6	equ	(6 << 10) | 0x202
Gsh6	equ	(6 << 10) | 0x220
A6	equ	(6 << 10) | 0x241
Ash6 	equ	(6 << 10) | 0x263
Bfl6	equ	(6 << 10) | 0x263	; alias
B6	equ	(6 << 10) | 0x287

section .text
start:	; first, detect Adlib (cannot proceed without it)
	call	al_chk
	jc	.hvlib
	mov	dx, err_no_adlib
	mov	ah, 9
	int	0x21
	jmp	.quit

	; program channel 1 to have a generic tone generator waveform
.hvlib:	mov	bl, 0			; channel 1 (0-based)
	mov	si, grand_piano
	call	al_cpr
	
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

	; Reset adlib and quit to DOS
.quit:	call	al_rst
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

	; update adlib state
	lea	bx, [notes + si]		; get address of "next note"
	cmp	bx, end_of_notes		; are we done?
	jb	.gogo
	mov	byte [cs:done], 1		; MARK US DONE
	pop	bx
	pop	si
	jmp	.clk				; and go to the clock
	

.gogo:	mov	bx, [cs:notes + si]		; get the next note freq (into BX)
	cmp	bx, 0				; are we turning the speaker OFF?
	je	.rest
	mov	ah, 0xb0			; turn voice off, to give definition to the notes
	xor	al, al
	call	al_wr				
	mov	ah, 0xa0			; no, write a new fnum/octave/key-on (chan 1)
	mov	al, bl				; LSByte first (to register a0)
	call	al_wr
	mov	ah, 0xb0
	mov	al, bh				; MSByte second...
	or	al, 0x20			; ... with the "key-on" bit, on top of the octave
	call	al_wr
	jmp	.txt

.rest:	mov	ah, 0xb0			; turn OFF that channel for a rest
	xor	al, al
	call	al_wr

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


	; write a byte to a given AdLib/OPL2 control register
	; AL=data byte, AH=register number
	; clobbers AX
al_wr:	push	cx
	push	dx
	xor	cx, cx				; set CX=0 so we can set loop-counts in just CL

	mov	dx, ADLIB_APORT
	xchg	al, ah				; swap; AL=reg#, AH=data
	out	dx, al				; write reg# to address-port
	mov	cl, 6				; wait 6-port-read cycles to "settle" the OPL2 chip
.wait1:	in	al, dx
	loop	.wait1

	xchg	al, ah				; AL=data again
	mov	dx, ADLIB_DPORT
	out	dx, al				; write data to data-port
	mov	dx, ADLIB_APORT
	mov	cl, 35				; wait 35-port-read cycles to "settle" the OPL2 chip
.wait2:	in	al, dx
	loop	.wait2

	pop	dx
	pop	cx
	ret

	; reset the AdLib card (write 0 to all OPL2 control registers)
	; clobbers nothing
al_rst:	push	cx
	push	bx
	push	ax

	mov	bl, 1				; first register number
	mov	cx, 0xf3			; number of registers
.regs:	mov	ah, bl
	xor	al, al
	call	al_wr
	inc	bl
	loop	.regs

	pop	ax
	pop	bx
	pop	cx
	ret

	; official "test presence of AdLib/OPL2" routine
	; return: CF=1 if present, CF=0 if not present
	; clobbers nothing
al_chk:	push	ax
	push	bx
	push	cx
	push	dx
	mov	dx, ADLIB_APORT			; set up DX for reading from the status port
	call	al_rst				; first, reset the card (on faith that it's there)
	mov	ax, 0x0460			; write 0x60 to register 4
	call	al_wr
	mov	ax, 0x0480			; write 0x80 to register 4
	call	al_wr
	in	al, dx				; read status port
	mov	bl, al				; stash in BL for future reference
	mov	ax, 0x02ff			; write 0xff to register 2
	call	al_wr
	mov	ax, 0x0421			; write 0x21 to register 4
	call	al_wr
	mov	cx, 140				; wait approx. 80us to check OPL2 timer expiration
.wait:	in	al, dx				; (i.e., 140 status-port read cycles)
	loop	.wait
	mov	bh, al				; stash last status in BH for our final result
	mov	ax, 0x0460			; again, write 0x60 to register 4
	call	al_wr
	mov	ax, 0x0480			; again, write 0x80 to register 4
	call	al_wr
	clc					; return logic: start with CF=0
	test	bl, 0xe0			; first status read, masked by 0xe0, should == 0
	jnz	.ret
	and	bh, 0xe0			; second status, masked by 0xe0, should == 0xc0
	cmp	bh, 0xc0
	jne	.ret
	stc					; if we made it here, we have an AdLib card!	
.ret:	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	; program an adlib channel's sound-generator parameters
	; BL=channel-num, DS:SI=pointer to 10-byte "parameter block"
	; clobbers AX, SI
al_cpr:	push	bx				; so we can 0 BH without trashing it
	push	di
	push	dx
	push	cx
	xor	bh, bh				; BX=channel-num; can use for array indexing	
	mov	dx, [achmsk]			; DX=channel offset 0/1 mask
	mov	di, achbas			; DI=ptr to our array of base-registers
	mov	cx, achoff-achbas		; assume one byte for each element of achbas
.prog:	lodsb					; load instrument data byte into AL
	mov	ah, [di]			; load base register into AH
	inc	di				; (advance to next byte in base-reg array)
	test	dx, 0x01			; is LSB of bit mask set?
	jz	.addch				; NO, just add the channel number	
	add	ah, [achoff + bx]		; YES, add achoff[ch#]
	jmp	.addgo				
.addch:	add	ah, bl				; offset the base register by CHANNEL NUMBER
.addgo:	call	al_wr				; write the data to the OPL2
	shr	dx, 1				; pop off a bit in the bit mask
	loop	.prog				; repeat for rest of data bytes
	pop	cx				; done/cleanup
	pop	dx
	pop	di
	pop	bx
	ret

	; adlib programming lookup tables
achbas:	db	0x20, 0x40, 0x60, 0x80, 0xe0, 0x23, 0x43, 0x63, 0x83, 0xe3, 0xc0	; base reg#s
achoff:	db	0x00, 0x01, 0x02, 0x08, 0x09, 0x0a, 0x10, 0x11, 0x12			; op1/op2 ch offsets
achmsk:	dw	0x3ff	; bit map telling how to modify the base-reg for each element of the instrument block...
			; 0=add ch# directly to base-reg; 1=add achoff[ch#]

	; an "acoustic grand piano" (ha) patch from the Allegro library's OPL2 MIDI player
grand_piano:
	db	0x21	; op1[0010 0001] :: am=0, vib=0, eg=1, ksr=0, harm=0001
	db	0x8f	; op1[1000 1111] :: scaling=10 [1.5dB/8ve] level=001111 [63-15=48]
	db	0xf2	; op1[1111 0010] :: attack=1111 [fastest], decay=0010 [slowish]
	db	0x45	; op1[0100 0101] :: sustain=0100 [lower], release=0101 [lower]
	db	0x00	; op1[0000 0000] :: unused=000000 wave=00 [sine-wave]
	db	0x21	; op2[0010 0001] :: am=0, vib=0, eg=1, ksr=0, harm=0001
	db	0x0c	; op2[0000 1100] :: scaling=00 [n/a] level=001100 [63-12=51]
	db	0xf2	; op2[1111 0010] :: attack=1111, decay=0010
	db	0x76	; op2[0111 0110] :: sustain=0111 [middle], release=0110 [middlish]
	db	0x00	; op2[0000 0000] :: unused=000000 wave=00 [sine-wave]
	db	0x08	; chan[0000 1000] :: unused=0000, feedback=100 [middle], alg=0 [modulate]
	
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
	dw 4, 4, 1, 10, 4, 4, 1, 10, 2, 4, 2, 4, 4, 16, 16
	dw 16, 16, 16, 16, 16, 16
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 16, 1, 4, 4, 32
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 2, 2, 4, 8, 4, 4, 4
	dw 4, 8, 4, 10, 4
	dw 4, 16, 1, 1
	dw 4, 2, 2, 10, 4, 4, 32
	
credits:
	db "    ******   ******   *******  =========================",CR,LF
	db "   *******  *******  *******  ============",CR,LF
	db "  **   **  **   **  *    **   (  |",CR,LF
	db " **   **  **   **       **  ____/",CR,LF
	db "*******  *******       **",CR,LF
	db "******   ******       **    James Bond", CR, LF
	db "                        "

err_no_adlib:
	db	"no Adlib detected; quitting...", CR, LF, "$"
