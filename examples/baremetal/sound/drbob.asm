; CpS 230 Demo Program: Unbounded 11025Hz 8-bit PCM raw audio player
;-------------------------------------------------------------------
; Note that multiple memory buffers, the IRQ 7 interrupt handler,
; and related logic (like unmasking IRQ 7 via the PIC mask port)
; are required only when playing audio samples > 64KB in size.
; Smaller samples can be played in one shot from a single buffer
; and do not need an interrupt handler (since there is no "next
; buffer" to load up and start transferring to the sound chip).

org 0x100

; Ports for programming the SoundBlaster DSP (digital signal processor)
SB_BASE		equ	0x20
SB_RESET	equ	SB_BASE + 0x206
SB_RDATA	equ	SB_BASE + 0x20A
SB_WDATA	equ	SB_BASE + 0x20C		; When read, returns status
SB_AVAIL	equ	SB_BASE + 0x20E
WAVE_FREQ	equ	11025	; hertz
WAVE_TC		equ	256 - (1000000 / WAVE_FREQ)

; Ports for manipulating the programmable interrupt controller (PIC)
PIC_CMD_PORT	equ	0x20
PIC_MASK_PORT	equ	0x21

; IRQ 7 (default SoundBlaster IRQ number for DOSBox) -> vector 0xF
IRQ_VECTOR_OFF	equ	(0xF * 4)
IRQ_VECTOR_SEG	equ	IRQ_VECTOR_OFF + 2

section .text
start:
	xor	ax, ax
	mov	es, ax
	
	; Install IRQ 7 handler to reload the DMA/DSP with the next buffer
	cli
	mov	ax, [es:IRQ_VECTOR_OFF]
	mov	[old_irq_off], ax
	mov	ax, [es:IRQ_VECTOR_SEG]
	mov	[old_irq_seg], ax
	mov	[es:IRQ_VECTOR_SEG], cs
	mov	word [es:IRQ_VECTOR_OFF], sound_irq
	sti
	
	; Unmask IRQ 7 via the primary PIC
	in	al, PIC_MASK_PORT
	mov	[old_pic_mask], al
	and	al, 0x7f
	out	PIC_MASK_PORT, al
	
	; Set our DMA buffers to be at physical address 0x20000 and 0x30000
	; Critically important that DMA transfers do not cross a 64KB alignment boundary
	; in memory (e.g., from 0x1ffff to 0x20000)!
	; Otherwise, very ... special ... things will happen.  And you will be sad...
	mov	word [wave_seg], 0x2000
	mov	word [wave_seg + 2], 0x3000
	
	; Open the file
	mov	ah, 0x3d
	mov	al, 0
	mov	dx, wave_fname
	int	0x21
	jc	boom
	mov	[wave_fd], ax
	
	; Reset the SoundBlaster
	call	reset_dsp
	jc	boom
	
	; Turn the speaker on
	mov	al, 0xd1
	call	write_dsp
	
	; Set the playback frequency on the DSP
	mov	al, 0x40
	call	write_dsp
	mov	al, WAVE_TC
	call	write_dsp
	
	; Read the first buffer, and start it playing
	call	load_buffer
	call	setup_dma
	
	; Read buffers as long as [wave_done] == 0
.buffload:
	cmp	byte [wave_done], 0
	jg	.playwait
	
	; Load the next buffer
	call	load_buffer
	
	; Wait for [wave_buff] <> ax (i.e., the DSP has picked it up)
.buffwait:
	cmp	[wave_buff], ax
	je	.buffwait
	
	jmp	.buffload
	
	; Wait until [wave_done] == 2
.playwait:
	cmp	byte [wave_done], 2
	jle	.playwait
	
	; Stop DMA, speaker off
	mov	al, 0xd0
	call	write_dsp
	mov	al, 0xd3
	call	write_dsp
	
	; Remask IRQ 7 via the primary PIC
	mov	al, [old_pic_mask]
	out	PIC_MASK_PORT, al
	
	; Uninstall IRQ 7 handler
	cli
	mov	ax, [old_irq_off]
	mov	[es:IRQ_VECTOR_OFF], ax
	mov	ax, [old_irq_seg]
	mov	[es:IRQ_VECTOR_SEG], ax
	sti
	
	; Quit to DOS
	mov	ah, 0x4c
	int	0x21

; Fatal error
boom:
	mov	ah, 9
	mov	dx, oops_msg
	int	0x21
	mov	ah, 0x4c
	int	0x21

; Interrupt handler that catches IRQ [hardware interrupt request] 7 (INT vector 0xF)
; when the SoundBlaster indicates that it is [nearly] done receiving an audio
; data dump via DMA.  This lets us set up another buffer (which has already been loaded
; from disk by the main thread of the program) for playback right away, resulting
; in uninterrupted sound even though we can never play more than 64KB of data at once.
sound_irq:
	push	ax
	push	dx
	
	; Acknowledge DSP (read from DATA AVAILABLE port)
	mov	dx, SB_AVAIL
	in	al, dx
	
	; Assume the necessary disk buffer has been setup, and
	; start the next buffer playing via DMA transfer
	call	setup_dma
	
	; Should we increment the done counter? (last buffer behavior)
	cmp	byte [cs:wave_done], 0
	je	.skip
	inc	byte [cs:wave_done]
.skip:
	
	; Acknowledge end-of-interrupt to the PIC
	mov	al, 0x20
	out	PIC_CMD_PORT, al
	
	; Return
	pop	dx
	pop	ax
	iret

; Reset the DSP (per instructions from PC-GPE)
; Clobbers: nothing
; Returns: CF=0 if reset went OK; CF=1 if reset failed
reset_dsp:
	push	ax
	push	cx
	push	dx
	
	mov	dx, SB_RESET
	mov	al, 1
	out	dx, al		; Take it HIGH
	
	mov	cx, 100		; Tiny delay between taking it high and low
	loop	$
	
	mov	al, 0
	out	dx, al		; Take it LOW
	
	mov	cx, 100		; Tiny delay between reset and test
	loop	$
	
	mov	dx, SB_AVAIL
	in	al, dx
	test	al, 0x80
	jz	.nope
	mov	dx, SB_RDATA
	in	al, dx
	cmp	al, 0xaa
	jne	.nope
	clc
	jmp	.end
.nope:
	stc
.end:
	pop	dx
	pop	cx
	pop	ax
	ret

; Write a command to the DSP
; Takes: value in AL
; Clobbers: nothing
; Returns: nothing
write_dsp:
	push	dx
	mov	dx, SB_WDATA
	
	push	ax
.wait:
	in	al, dx
	test	al, 0x80
	jnz	.wait
	
	pop	ax
	out	dx, al
	
	pop	dx
	ret

; Read data from DSP
; Takes: nothing
; Clobbers: AL
; Returns: byte value in AL
read_dsp:
	push	dx
	mov	dx, SB_AVAIL
.wait:
	in	al, dx
	test	al, 0x80
	jz	.wait
	
	mov	dx, SB_RDATA
	in	al, dx
	
	pop	dx
	ret

; Load data from [wave_fd] into the current [wave_buff]
; Takes: none
; Returns: buffer number in AX (and [wave_done] is incremented if < 64KB is read from the file)
; Clobbers: none
load_buffer:
	push	bx
	push	cx
	push	dx
	
	; Find the segment of the current loading buffer
	mov	bx, [wave_buff]
	shl	bx, 1
	mov	ax, [wave_seg + bx]
	shr	bx, 1
	push	bx
	push	ds
	mov	ds, ax
	
	; Slurp from the file into our buffer
	mov	ah, 0x3f
	mov	bx, [cs:wave_fd]
	mov	cx, 0xffff
	xor	dx, dx
	int	0x21
	pop	ds
	pop	bx
	jc	boom
	
	cmp	ax, cx
	je	.full
	inc	byte [wave_done]
.full:
	dec	ax
	mov	[wave_size], ax		; [wave_size] = (size_read - 1)
	mov	ax, bx
	
	pop	dx
	pop	cx
	pop	bx
	ret

; Set up the DMA chip for the currently selected buffer (updates buffer after setup)
; Takes: nothing
; Returns: nothing
; Clobbers: nothing
setup_dma:
	pusha
	
	; Find the segment of the current loading buffer and then swap buffers
	mov	bx, [wave_buff]
	shl	bx, 1
	mov	ax, [wave_seg + bx]
	shr	bx, 1
	inc	bx
	and	bx, 1
	mov	[wave_buff], bx
	
	; Compute page/base physical address of segment
	mov	bx, ax
	shl	bx, 4		; Plus an offset of 0000
	mov	cx, ax
	shr	cx, 12		; Top 4 bits of final address in the BOTTOM of CX (i.e., CL)
	
	; Set up a DMA (Direct Memory Access) transfer
	mov	al, 5
	out	0x0a, al	; Write 5 -> DMA mask register (set mask, selecting channel 1)
	mov	al, 0
	out	0x0c, al	; Reset DMA chip's internal pointers
	mov	al, 0x49
	out	0x0b, al	; Write 0b0100_1001 to DMA mode register (signal mode read, channel 1)
	mov	al, bl
	out	0x02, al	; Write LSB of lowest 16-bits of address to channel 1 address port
	mov	al, bh
	out	0x02, al	; Write MSB of lowest 16-bits of address to channel 1 address port
	mov	al, cl
	out	0x83, al	; Write top 4 bits of address to channel 1 "page" port
	mov	bx, [wave_size]
	mov	al, bl
	out	0x03, al	; Write LSB of (size - 1) to channel 1 length port
	mov	al, bh
	out	0x03, al	; Write MSB of (size - 1) to channel 1 length port
	mov	al, 1
	out	0x0a, al	; Clear DMA mask bit for channel 1 (i.e., we're done)
	
	; Set playback type (8-bit PCM)
	mov	al, 0x14
	call	write_dsp
	mov	bx, [wave_size]
	mov	al, bl
	call	write_dsp
	mov	al, bh
	call	write_dsp

	popa
	ret

section .data
old_irq_off	dw	0
old_irq_seg	dw	0
old_pic_mask	db	0
oops_msg	db	"Something went BOOM...", 13, 10, "$"
wave_fname	db	"drbob.snd", 0
wave_fd		dw	0	; file descriptor for open snd file
wave_size	dw	0	; bytes of data in current/active buffer
wave_seg	dw	0, 0	; ping-pong buffer segments (one active, one loading)
wave_buff	dw	0	; loading buffer (0 or 1; the other is active/playing)
wave_done	db	0	; 0=more to play, 1=loaded last buffer, 2=started last buffer, 3=done
