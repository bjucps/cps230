/* compile with `TCC -mt -lt ADLIB.C` to get ADLIB.COM */
#include <stdio.h>
#include <dos.h>

#define ADLIB_APORT	0x0388
#define ADLIB_DPORT	0x0389

static union REGS regs;

unsigned char read_status() {
	return inportb(ADLIB_APORT);
}

void wait_cycles(int count) {
	int i;
	for (i = 0; i < count; ++i) {
		inportb(ADLIB_APORT);
	}
}

void write_register(unsigned char reg, unsigned char value) {
	outportb(ADLIB_APORT, reg);
	wait_cycles(6);
	outportb(ADLIB_DPORT, value);
	wait_cycles(35);	
}

void reset_adlib() {
	int reg;
	for (reg = 1; reg < 0xf4; ++reg)
		write_register(reg, 0);
}

int check_adlib() {
	unsigned char check1, check2;
	reset_adlib();
	write_register(4, 0x60);
	write_register(4, 0x80);
	check1 = read_status();
	write_register(2, 0xff);
	write_register(4, 0x21);
	wait_cycles(140);  /* approx. 80ms delay */
	check2 = read_status();
	write_register(4, 0x60);
	write_register(4, 0x80);
	return ((check1 & 0xe0) == 0) && ((check2 & 0xe0) == 0xc0);
}

int main() {
	if (!check_adlib()) {
		puts("no Adlib detected");
		return 1;
	}
	puts("Adlib detected!");

	write_register(0x20, 0x01);	/* ch1, op1, amp/vib/eg/ksr/mult */
	write_register(0x40, 0x10);	/* ch1, op1, key-scale/operator-output-level */
	write_register(0x60, 0xf0);	/* ch1, op1, attack/decay */
	write_register(0x80, 0x77);	/* ch1, op1, sustain/release */
	write_register(0xA0, 0x98);	/* ch1, op1, freq LSB */
	write_register(0x23, 0x01);	/* ch1, op2, amb/vib/eg/ksr/mult */
	write_register(0x43, 0x00);	/* ch1, op2, key-scale/operator-output-level */
	write_register(0x63, 0xf0);	/* ch1, op2, attack/decay */
	write_register(0x83, 0x77);	/* ch1, op2, sustain/release */
	write_register(0xB0, 0x31);	/* ch1, op1, key-on/octave/freq MSbb */

	regs.x.ax = 0;
	int86(0x16, &regs, &regs);

	reset_adlib();
	return 0;
}
