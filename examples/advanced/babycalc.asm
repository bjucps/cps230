bits 64
default rel

; export our main function (for linking with libc into a complete program)
global main

; libC functions we use
extern printf
extern scanf

; read-only data (for string literals)
section .rdata
infmt	db	"%d %c %d", 0
outfmt	db	">> %d %c %d = %d", 0xa, 0

; R/W data (global variables)
section .data
op1	dd	0			; dd -> 32-bit -> like a C `int`
op2	dd	0			; ditto
oper	db	0			; db -> 8-bit -> like a C `char`

; machine code section
section .text
main:	push	rbp			; function prologue: save frame pointer and reserve stack space
	mov	rbp, rsp
	sub	rsp, 48			; 0x30 bytes / 6 qword slots

.prompt:
	; call scanf to get our inputs
	lea	r9, [op2]
	lea	r8, [oper]
	lea	rdx, [op1]
	lea	rcx, [infmt]
	call	scanf

	; check for failure from scanf
	cmp	eax, 3
	je	.ok
	jmp	.success		; assume we got EOF, so don't consider it an error

	; parse operator / branch to appropriate logic
.ok:	mov	eax, [op1]		; (put op1 in eax before branching to op-specific logic)
	cmp	byte [oper], '+'
	je	.add
	cmp	byte [oper], '-'
	je	.sub
	cmp	byte [oper], '*'
	je	.mul
	cmp	byte [oper], '/'
	je	.div
	jmp	.failure

	; per-operator logic blocks
.add:	add	eax, [op2]
	jmp	.show
.sub:	sub	eax, [op2]
	jmp	.show
.mul:	imul	dword [op2]
	jmp	.show
.div:	cdq
	idiv	dword [op2]

	; call printf to show our ouput
.show:	mov	[rsp + 32], eax		; argument 5: the calculated value from EAX ("pushed onto stack")
	mov	r9d, [op2]		; argument 4: 32-bit integer from memory at `op2`
	movzx	r8d, byte [oper]	; argument 3: 8-bit ASCII char from memory at `oper`, 0-extended to 32-bit integer value
	mov	edx, [op1]		; argument 2: 32-bit integer from memory at `op1`
	lea	rcx, [outfmt]		; argument 1: 64-bit address of `outfmt` string
	call	printf

	; repeat loop with another prompt
	jmp	.prompt
.success:
	xor	eax, eax		; return 0 (success)
	jmp	.return
.failure:
	mov	eax, 1			; return non-0 (failure)
.return:
	add	rsp, 48			; function epilogue: back out our stack space and saved frame pointer
	mov	rsp, rbp
	pop	rbp
	ret
