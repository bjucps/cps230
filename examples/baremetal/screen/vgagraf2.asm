bits 16

org 0x100

start:
	push    bp                      ; 16-bit version of prolog
	mov     bp, sp
	
	mov     ah, 0x0
	mov     al, 0x13
	int     0x10                    ; set video to vga mode (320x200 pixels, 256 color palette mode)

	sub     sp, 6                   ; three local stack variables, bp - 2 = row iter, bp - 4 = col iter, bp - 6 = color
	mov     word [bp - 6], 0        ; start at color
	mov     word [bp - 2], 0        ; start row iter at 0
.color_row_loop:
	cmp     word [bp - 2], 13       ; with 15 x 15 blocks, we can fit roughly 13 rows
	jne     .continue_color_row
	jmp     .exit
.continue_color_row:
	mov     word [bp - 4], 0        ; start col iter at 0
.color_column_loop:
	cmp     word [bp - 4], 21       ; with 15 x 15 blocks, we can have roughly 21 columns
	jne     .continue_color_column
	jmp     .color_column_done
.continue_color_column:
	mov     ax, [bp - 2]            ; copy row iter
	mov     bx, 15                  ; block height
	imul    bx
	mov     di, ax                  ; row offset

	mov     ax, [bp - 4]            ; copy col iter
	mov     bx, 15                  ; block width
	imul    bx
	mov     si, ax                  ; column offset

	mov     dx, [bp - 6]            ; current color
	call    _draw_block

	inc     word [bp - 6]           ; next color
	inc     word [bp - 4]           ; next column
	jmp     .color_column_loop
.color_column_done:
	inc     word [bp - 2]           ; next row
	jmp     .color_row_loop
.exit:
	mov     ah, 0x0                 ; wait for user input
	int     0x16

	mov     sp, bp
	pop     bp

	mov     ah, 0x0
	mov     al, 0x03
	int     0x10                    ; set video to text mode (80x25 cells, 16 fg / 8 bg colors)

	mov     ah, 0x4c
	mov     al, 0
	int     0x21

; di - row
; si - column
; dx - color
_draw_block:
	push    bp                      ; 16-bit version of prolog
	mov     bp, sp
	sub     sp, 6                   ; three local variables, bp - 2 = row iter, bp - 4 = col iter, bp - 6 = color
	mov     [bp - 6], dx

	mov     ax, 0xA000
	mov     es, ax                  ; need location in memory to write to
	
	mov     word [bp - 2], 0        ; row iter
.row_loop:
	cmp     word [bp - 2], 15       ; < 15
	jne     .continue_row
	jmp     .done_row
.continue_row:
	mov     word [bp - 4], 0        ; col iter
.column_loop:
	cmp     word [bp - 4], 15       ; < 15
	jne     .continue_column
	jmp     .column_done
.continue_column:
	mov     ax, di                  ; row
	add     ax, [bp - 2]
	mov     bx, 320                 ; size of row in vga
	imul    bx

	mov     bx, si                  ; col
	add     bx, [bp - 4]
	add     bx, ax

	mov     cx, [bp - 6]            ; color
	mov     [es:bx], cx             ; write to screen

	inc     word [bp - 4]           ; increment col
	jmp     .column_loop
.column_done:
	inc     word [bp - 2]           ; increment row
	jmp     .row_loop
.done_row:
	mov     sp, bp
	pop     bp
	ret
