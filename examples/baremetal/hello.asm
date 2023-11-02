bits 16

org 0x100

start:
	mov	dx, hello_msg
	mov	ah, 0x09
	int	0x21

	mov	ah, 0x4c
	int	0x21

hello_msg	db	"Hello, world!", 13, 10, "$"

