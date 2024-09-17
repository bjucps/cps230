#include <stdio.h>
#include <stdint.h>

int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "usage: %s UTF8_HEX_BYTES\n", argv[0]);
		return 1;
	}

	uint8_t bytes[5] = { 0 };
	int nbytes = 0;
	for (int i = 1; i < argc; ++i) {
		if (sscanf(argv[i], "%hhx", &bytes[nbytes]) != 1) {
			fprintf(stderr, "error parsing '%s'\n", argv[i]);
			return 1;
		}
		++nbytes;
	}

	int cp = 0;
	if ((bytes[0] & 0x80) == 0 && (nbytes == 1)) {
		cp = bytes[0] & 0x7f;
		printf("%02x -> codepoint 0x%x (%s)\n", bytes[0], cp, bytes);
	} else if ((bytes[0] & 0xe0) == 0xc0 && (nbytes == 2)) {
		cp = ((bytes[0] & 0x1f) << 6) | (bytes[1] & 0x3f);
		printf("%02x %02x -> codepoint 0x%x (%s)\n", bytes[0], bytes[1], cp, bytes);
	} else if ((bytes[0] & 0xf0) == 0xe0 && (nbytes == 3)) {
		cp = ((bytes[0] & 0x0f) << 12) | ((bytes[1] & 0x3f) << 6) | (bytes[2] & 0x3f);
		printf("%02x %02x %02x -> codepoint 0x%x (%s)\n", bytes[0], bytes[1], bytes[2], cp, bytes);
	} else if ((bytes[0] & 0xf8) == 0xf0 && (nbytes == 4)) {
		cp = ((bytes[0] & 0x07) << 18) | ((bytes[1] & 0x3f) << 12) | ((bytes[2] & 0x3f) << 6) | (bytes[3] & 0x3f);
		printf("%02x %02x %02x %02x -> codepoint 0x%x (%s)\n", bytes[0], bytes[1], bytes[2], bytes[3], cp, bytes);
	} else {
		fprintf(stderr, "0x%02x is an invalid first-byte for a %d-byte UTF-8 encoding!\n", bytes[0], nbytes);
		return 1;
	}

	return 0;
}
