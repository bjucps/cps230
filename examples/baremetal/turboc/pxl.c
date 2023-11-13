/* compile with `TCC -B -mt -lt PXL.C` to get PXL.COM */

void drawpixel(int x, int y, int color)
{
	asm push ax
	asm push bx
	asm push cx
	asm push dx
	asm mov ah, 0x0c
	asm mov al, [bp + 8]
	asm mov cx, [bp + 6]
	asm mov dx, [bp + 4]
	asm int 0x10
	asm pop dx
	asm pop cx
	asm pop bx
	asm pop ax
}

int checkkey() {
	asm xor ax, ax
	asm mov ah, 0x01
	asm int 0x16
	asm jnz keyhit
	return 0;
keyhit:
	return 1;

}

void drawline() {
	int x = 0, y = 0;
	int xi = 1, yi = 1;
	int delay;
	unsigned char cc = 1;

	for (;;) {
		if (x == 0) {
			xi = 1;
		} else if (x == 200) {
			xi = 0;
		}
		if (y == 0) {
			yi = 1;
		} else if (y == 320) {
			yi = 0;
		}
		x = x + (xi ? 1 : -1);
		y = y + (yi ? 1 : -1);
		drawpixel(x, y, cc++);
		if (checkkey()) return;
		for (delay=0;delay<1000;++delay);
	}
}

void main() {
	asm mov ax, 0x0013
	asm int 0x10

	drawline();

	asm mov ah, 0x00
	asm int 0x16

	asm mov ax, 0x0003
	asm int 0x10
}

