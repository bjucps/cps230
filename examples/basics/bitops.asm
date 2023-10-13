bits 64
default rel

extern printf
extern scanf

SECTION .data

value:	dd	0                       ; dd -> 32-bit variable (must use 32-bit registers [Exx] and operations)
infmt:	db	"%x", 0
outfmt:	db	"0x%x", 10, 0

SECTION .text

global main
main:
	push	rbp			; MAGIC BOILERPLATE ("function prologue")
	mov	rbp, rsp
	sub	rsp, 32			; REQUIRED MAGIC BOILERPLATE

	lea	rdx, [value]		; rdx = &value
	lea	rcx, [infmt]		; rcx = address-of "%x"
	call	scanf			; scanf("%x", &value)

	mov	eax, [value]		; eax = value
	shr	eax, 1			; eax = eax >> 1 = (value >> 1)
	or	[value], eax		; value = value | (value >> 1)
	mov	eax, [value]		; eax = value
	shr	eax, 2			; eax = eax >> 2 = (value >> 2)
	or	[value], eax		; value = value | (value >> 2)
	mov	eax, [value]		; eax = value
	shr	eax, 4			; eax = eax >> 4 = (value >> 4)
	or	[value], eax		; value = value | (value >> 4)
	mov	eax, [value]		; eax = value
	shr	eax, 8			; eax = eax >> 8 = (value >> 8)
	or	[value], eax		; value = value | (value >> 8)
	mov	eax, [value]		; eax = value
	shr	eax, 16			; eax = eax >> 16 = (value >> 16)
	or	[value], eax		; value = value | (value >> 16)

	mov	eax, [value]
	shr	eax, 1
	xor	[value], eax

	mov	edx, [value]		; edx = value			[parameter 2]
	lea	rcx, [outfmt]		; rcx = address-of "0x%x\n"	[parameter 1]
	call	printf			; printf(rcx, rdx)
	
	add	rsp, 32			; REQUIRED MAGIC BOILERPLATE
	xor	rax, rax		; rax = 0 (return 0 from main function)

	mov	rsp, rbp		; MAGIC BOILERPLATE ("function epilogue")
	pop	rbp
	ret				; actual return from main
