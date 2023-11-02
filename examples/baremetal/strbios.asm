; example program from lecture notes on using BIOS services

bits 16
org	0x100

section .text
_main:
	lea     si, [prompt]
	call    putstring	; a custom function to print a NUL-terminated string (see below)

	lea     di, [buffer]
	mov	cx, buflen
	call    getstring       ; a custom function to read and NUL-terminate a '\r'-terminated string (see below)

	lea     si, [hello]
	call    putstring

	lea     si, [buffer]
	call    putstring

	mov	ah, 0x4c        ; standard exit code
	mov	al, 0
	int	0x21		; make a "system call" to DOS (to exit our program, return to DOS prompt)

getchar:
; description: read next character from keyboard into AL
; inputs: n/a
; clobbers: AX
	mov     ah, 0           ; call interrupt x16 sub interrupt 0
	int     0x16
	mov     ah, 0
	ret

putchar:
; description: print character in AL to screen, TTY-style
; inputs: AL (input character)
; clobbers: AX
	mov     ah, 0x0E
	int     0x10
	ret

getstring:
; description: read '\r'-terminated string from console into buffer (NUL-terminating)
; inputs: DI (offset of destination buffer), CX (size of destination buffer)
; clobbers: DI, CX, AX, DF (direction flag--cleared)
	cld			; DF=0 -> DI++ on STOSB (move _forward_ in buffer)
	jcxz	.oops		; if CX is 0 (empty buffer), just bail out (no NUL termination)
	dec	cx		; --CX
	jcxz	.done		; if CX was 1 (i.e., is 0 now), jump straight to NUL-termination
.loop:	call    getchar		; read a character
	cmp     al, 13		; halt on '\r' (pressing ENTER gives us this)
	je      .done		;       (go to NUL-termination)
	stosb			; equivalent to "MOV AL, [DI]" then "INC DI"
	call    putchar		; echo character (so user can see what is typed)
	loop	.loop

.done:	xor	al, al		; NUL-out AL
	stosb			; NUL-terminate the string
	mov     al, 13		; and echo a CRLF pair to keep the display tidy
	call    putchar
	mov     al, 10
	call    putchar
.oops:	ret


putstring:
; description: print NUL-terminated string to screen
; inputs: SI (offset of NUL-terminated string)
; clobbers: AX, DF (direction flag)
	cld		; clear DF == LODSB will move _forward_ (SI++)
.loop:	lodsb		; MOV AL, [SI] and INC SI	
	cmp     al, 0   ; see if the current byte is a null terminator
	je     	.done	; if yes, break out; else, keep printing
	call    putchar	; print char in AL
	jmp     .loop	; load the next byte
.done:
	ret

section .data
prompt	db "Please enter your first name: ", 0
buffer	times 32 db 0
buflen	equ ($ - buffer) ; (define "buflen" as a constant symbol equal to the allocated size of "buffer")
hello	db "Hello, ", 0
