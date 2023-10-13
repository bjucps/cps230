#include <stdio.h>
#include <string.h>
#include <ctype.h>

const char WS[] = " \t\r\n";

int main() {
	char buff[80];

	puts("Enter a line of text: ");
	fgets(buff, sizeof buff, stdin);

	printf("As entered: \"%s\"\n", buff);

	size_t leading_ws_chars = strspn(buff, WS);
	char *stripped = buff + leading_ws_chars;

	// No handy reverse-strspn (strcspn is not what we need)...have to do it by hand
	char *cp = buff + strlen(buff) - 1;
	while ((cp >= stripped) && isspace(*cp)) {
		*cp = '\0';
		--cp;
	}

	printf("Stripped: \"%s\"\n", stripped);


	return 0;
}
