; my first hello world program in NASM for x64/Windows
[bits 64]

default rel

extern printf

section .data
fmt_string	db	"hello, world", 0xa, 0

global main
section .text
main:	sub	rsp, 40

	lea	rcx, [fmt_string]
	call	printf

	xor	eax, eax	
	add	rsp, 40
	ret


