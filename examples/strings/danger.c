#include <stdio.h>
#include <string.h>

volatile char *shutup = NULL;

char *danger(char *name) {
	char msg[80];
	snprintf(msg, sizeof msg, "Watch out, %s!", name);
	shutup = (volatile void *)msg;
	return shutup;
}


int main() {
	char *m1 = danger("Fred");
	char *m2 = danger("Trumpington Fanhurst XXIV, Esq.");

	puts(m1);
	puts(m2);

	return 0;
}
