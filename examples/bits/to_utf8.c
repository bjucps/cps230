#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "usage: %s CODE_POINT_INTEGER\n", argv[0]);
		return 1;
	}

	unsigned long codepoint = strtoul(argv[1], NULL, 16);
	if (codepoint == 0 || codepoint > 0x10ffff) {
		fprintf(stderr, "invalid code point 0x%lx\n", codepoint);
		return 1;
	}

	uint8_t bytes[5] = { 0 };
	int nbytes = 0;
	if (codepoint < 0x80) {
		bytes[0] = (uint8_t)codepoint;
		nbytes = 1;
	} else if (codepoint < 0x800) {
		bytes[0] = 0xc0 | ((codepoint >> 6) & 0x1f);
		bytes[1] = 0x80 | (codepoint & 0x3f);
		nbytes = 2;
	} else if (codepoint < 0x10000) {
		bytes[0] = 0xe0 | ((codepoint >> 12) & 0x0f);
		bytes[1] = 0x80 | ((codepoint >> 6) & 0x3f);
		bytes[2] = 0x80 | (codepoint & 0x3f);
		nbytes = 3;
	} else {
		bytes[0] = 0xf0 | ((codepoint >> 18) & 0x07);
		bytes[1] = 0x80 | ((codepoint >> 12) & 0x3f);
		bytes[2] = 0x80 | ((codepoint >> 6) & 0x3f);
		bytes[3] = 0x80 | (codepoint & 0x3f);
		nbytes = 4;
	}

	printf("codepoint 0x%lx is UTF-8 encoded as %d bytes:", codepoint, nbytes);
	for (int i = 0; i < nbytes; ++i) printf(" 0x%02x", bytes[i]);
	printf("\nif your terminal supports utf-8, this is what codepoint 0x%lx looks like: %s\n", codepoint, bytes);

	return 0;
}
