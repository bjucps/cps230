#include <stdio.h>

typedef struct tagged_union {
    enum { TU_CHAR, TU_INT, TU_DOUBLE } type;
    union {
        char c;
        int i;
        double d;
    } data;
} tu_t;

void print_tu_t(tu_t tt) {
    switch (tt.type) {
    case TU_CHAR:
        printf("'%c'", tt.data.c);
        break;
    case TU_INT:
        printf("%d", tt.data.i);
        break;
    case TU_DOUBLE:
        printf("%lf", tt.data.d);
        break;
    default:
        printf("error: unknown type %d\n", tt.type);
        break;
    }
}

int main() {
    tu_t t1 = { TU_CHAR, { .c = 'z' }};
    tu_t t2 = { TU_INT, { .i = 42 }};

    printf("t1 = "); print_tu_t(t1); putchar('\n');
    printf("t2 = "); print_tu_t(t2); putchar('\n');

    return 0;
}

