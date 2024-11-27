#include <stdio.h>
#include <string.h>

int main() {
	int foo[5] = {1, 2, 3, 4, 5}; // OK, this is an _initializer_
	int bar[3];

	// one way to copy/assign ("bar = foo")
	for (int i = 0; i < (sizeof foo / sizeof foo[0]); ++i) {
		bar[i] = foo[i];
	}

	// memcpy is another way
	memcpy(bar, foo, sizeof foo);	// but you need to understand pointers first to really get it...

	return 0;
}
