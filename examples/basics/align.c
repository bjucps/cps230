#include <stdio.h>

#define EXAMPLE_FIELDS \
    X(char, c, "'%c'")\
    X(int, i, "%d")\
    X(double, d, "%lf")\

typedef struct example {
    #define X(type, name, fmt) type name;
    EXAMPLE_FIELDS
    #undef X
} ex_t;

int main() {
    ex_t ex1 = { .c = 'x', .i = 42, .d = 3.1415926}, ex2;

	printf("type ex_t is %zu bytes long\n", sizeof ex1);
    
    #define X(type, name, fmt) printf("ex1." #name " = " fmt " (@%p)\n", ex1.name, &ex1.name);
    EXAMPLE_FIELDS
    #undef X
	
	printf("&ex1 = %p; &ex2 = %p\n", &ex1, &ex2);

    return 0;
}
