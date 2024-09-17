#include <stdio.h>
#include <stdint.h>

int main() {
	uint32_t raw_address = 0u;

	printf("Please enter a 32-bit integer in hexadecimal notation: 0x");
	scanf("%x", &raw_address);

	int parts[4] = {
		(raw_address & 0xff000000) >> 24,
		(raw_address & 0x00ff0000) >> 16,
		(raw_address & 0x0000ff00) >> 8,
		(raw_address & 0x000000ff),
	};

	printf("That is %d.%d.%d.%d in 'dotted quad' IPv4 notation!\n", parts[0], parts[1], parts[2], parts[3]);
	return 0;
}
