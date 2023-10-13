bits 64
default rel

global main

extern getchar
extern putchar
extern exit

section .text

; helper function: get next char; terminate program cleanly on EOF
nextc:	sub	rsp, 40
	call	getchar
	cmp	eax, 0
	jge	.ok

	mov	ecx, 10		; '\n'
	call	putchar

	xor	rcx, rcx
	call	exit

.ok:	add	rsp, 40
	ret

; helper [leaf] function: return non-zero if char in CL is "word" char
isword:	xor	eax, eax
	cmp	cl, ` `
	je	.no
	cmp	cl, `\t`
	je	.no
	cmp	cl, `\r`
	je	.no
	cmp	cl, `\n`
.yes:	inc	eax
.no:	ret


; main function: read from STDIN, eat all non-word characters, emitting "words" one-per-line to STDIN
main:	push	rbp
	mov	rbp, rsp
	push	rbx
	sub	rsp, 40

.nwtop:	call	nextc			; the "not word" state--read a char
	movzx	ebx, al
	mov	ecx, ebx
	call	isword
	cmp	eax, 0
	je	.nwtop			; keep not-a-wording
	jmp	.iwput			; we are now it a word--print char

.iwtop:	call	nextc			; the "in word" state--read a char
	movzx	ebx, al
	mov	ecx, ebx
	call	isword
	cmp	eax, 0
	jne	.iwput			; yes, still a word, print and continue
	
	mov	ecx, 10			; print newline and transition to not-word
	call	putchar
	jmp	.nwtop

.iwput:	mov	ecx, ebx		; print char in BL and continue "in-word"
	call	putchar
	jmp	.iwtop

.eof:	xor	eax, eax
	add	rsp, 40
	pop	rbx
	pop	rbp
	ret

