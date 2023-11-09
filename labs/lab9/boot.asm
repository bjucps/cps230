; CpS 230 Lab 9: Alice B. College-Student (acoll555)
;---------------------------------------------------
; Combined bootloader/MBR source code with NASM
; preprocessor-fu to embed a pre-assembled "payload"
; second-stage program into a full 1.44MiB bootable
; floppy-disk image file.
;---------------------------------------------------
bits 16

; The BIOS will load us into memory at 0000:7C00h; NASM needs
; to know this so it can generate correct absolute data references.
org	0x7C00

; First instruction: jump over initial data and start executing code
start:	jmp	main

; Embedded data
boot_msg	db	"CpS 230 Bootloading Lab", 13, 10
		db	"by YOUR NAME HERE", 13, 10, 0
retry_msg	db	"Error reading payload from disk; retrying...", 13, 10, 0

boot_disk	db	0			; Variable to store the number of the disk we boot from
payload_size	db	__PAYLOAD_SECTORS	; to be populated by NASM's preprocessor once it knows how big the payload is

main:
	; TODO: Set DS == CS (so data addressing is normal/easy)
	; TODO: Save the boot disk number (we get it in register DL
	; TODO: Set SS == 0x0800 (which will be the segment we load everything into later)
	; TODO: Set SP == 0x0000 (stack pointer starts at the TOP of segment; first push decrements by 2, to 0xFFFE)
	; TODO: Print the boot message/banner
	
	; TODO: use BIOS raw disk I/O to load sectors 2-payload_size from disk number <boot_disk>
	; into memory at 0800:0000h (retry on failure)
	
	; Finally, jump to address 0800h:0000h (sets CS == 0x0800 and IP == 0x0000)
	jmp	0x0800:0x0000

; print NUL-terminated string from DS:DX to screen using BIOS (INT 10h)
; takes NUL-terminated string pointed to by DS:DX
; clobbers nothing
; returns nothing
puts:
	push	ax
	push	cx
	push	si
	
	mov	ah, 0x0e
	mov	cx, 1		; no repetition of chars
	
	mov	si, dx
.loop:	mov	al, [si]
	inc	si
	cmp	al, 0
	jz	.end
	int	0x10
	jmp	.loop
.end:
	pop	si
	pop	cx
	pop	ax
	ret

; NASM mumbo-jumbo to make sure the boot sector signature starts 510 bytes from our origin
; (logic: subtract the START_ADDRESS_OF_OUR_SECTION [$$] from the CURRENT_ADDRESS [$],
;	yielding the number of bytes of code/data in the section SO FAR; then subtract
;	this size from 510 to give us BYTES_OF_PADDING_NEEDED; finally, emit
;	BYTES_OF_PADDING_NEEDED zeros to pad out the section to 510 bytes)
	times	510 - ($ - $$)	db	0

; MAGIC BOOT SECTOR SIGNATURE (*must* be the last 2 bytes of the 512 byte boot sector)
	dw	0xaa55

; NASM magic to include a pre-assembled payload program, "payload.bin"
incbin	"payload.bin"

; Calculate the size of the payload in 512-byte sectors
; (logic: subtract the START_ADDRESS_OF_OUR_SECTION [$$] from the CURRENT_ADDRESS [$],
;	yielding the number of bytes in the image SO FAR.  Round this value up to the
;	nearest multiple of 512 by _adding_ 511 and _masking_ the result by the bit-
;	inverse of 511.  Finally, divide this total by 512 to yield the number
;	of disk sectors that must be loaded to get the entire payload into memory.)
__PAYLOAD_SECTORS equ ((($ - $$) + 511) & ~511) / 512

; Fill out the rest of the image to 1.44MiB with 0 padding (same logic as the MBR padding)
	times	(1440 * 1024) - ($ - $$) db	0

