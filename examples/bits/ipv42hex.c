#include <stdio.h>
#include <stdint.h>

int main() {
	uint8_t parts[4] = { 0 };

	printf("Please enter an IPv4 address in 'dotted-quad' notation: ");
	scanf("%hhu.%hhu.%hhu.%hhu", &parts[0], &parts[1], &parts[2], &parts[3]);

	uint32_t raw_address = (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3];
	printf("That is 0x%08x in raw hex form!\n", raw_address);
	return 0;
}
