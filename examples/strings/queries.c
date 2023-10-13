#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main() {
	int ret = EXIT_FAILURE;
	char haystack[80];
	char needle;
	char needle_str[10];

	puts("Please enter a line of text:");
	if (fgets(haystack, sizeof haystack, stdin) == NULL) {	// check error
		perror("fgets"); 	// report error
		goto cleanup;		// terminate right now
	}

	printf("Please enter a character to search for: ");
	if (scanf(" %c", &needle) != 1) {
		perror("scanf");
		goto cleanup;
	}

	char *np = strchr(haystack, needle);
	if (np != NULL) {
		printf("The character '%c' is found at offset %zu!\n", needle, (np - haystack));
	} else {
		printf("No '%c' character found!\n", needle);
	}

	printf("Please enter a substring to search for: ");
	if (scanf(" %9[^\n]", needle_str) != 1) {
		perror("scanf");
		goto cleanup;
	}

	np = strstr(haystack, needle_str);
	if (np != NULL) {
		printf("The substring \"%s\" is found at offset %zu!\n", needle_str, (np - haystack));
	} else {
		printf("No '%s' substring found!\n", needle_str);
	}

	ret = EXIT_SUCCESS;
cleanup:
	return ret;
}
