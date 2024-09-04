#include <stdio.h>

int divmod(int numer, int denom, int *remainder) {
    *remainder = numer % denom;
    return numer / denom;
}

int main() {
    int q, r;
    q = divmod(42, 5, &r);
    printf("42 / 5 = %d r%d\n", q, r);
    return 0;
}
