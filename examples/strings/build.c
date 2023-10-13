#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
	char first_name[32];
	char last_name[32];
	char normal_buff[96];
	char phone_book_buff[96];

	if (argc < 2 || (strcmp(argv[1], "old") != 0 && strcmp(argv[1], "new") != 0)) {
		fprintf(stderr, "usage: %s (old|new)\n", argv[0]);
		return 1;
	}

	printf("First name? ");
	fgets(first_name, sizeof first_name, stdin);
	first_name[strcspn(first_name, "\n")] = '\0'; 	// rstrip a '\n' via clever strcspn hack
	
	printf("Last name? ");
	fgets(last_name, sizeof last_name, stdin);
	last_name[strcspn(last_name, "\n")] = '\0';

	// OLD BUSTED WAY:
	if (strcmp(argv[1], "old") == 0) {
		strcpy(normal_buff, first_name);
		strcat(normal_buff, " ");
		strcat(normal_buff, last_name);

		strcpy(phone_book_buff, last_name);
		strcat(phone_book_buff, ", ");
		strcat(phone_book_buff, first_name);
	}
	
	// MUCH BETTER WAY:
	if (strcmp(argv[1], "new") == 0) {
		snprintf(normal_buff, sizeof normal_buff, "%s %s", first_name, last_name);
		snprintf(phone_book_buff, sizeof phone_book_buff, "%s, %s", last_name, first_name);
	}

	printf("Your name is %s, but in a phone book, you'd be listed as \"%s\"!\n", normal_buff, phone_book_buff);

	return 0;
}
