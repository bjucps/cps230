#include <stdio.h>

void fun(int *anonymous) {
    printf("fun: anonymous integer is initially %d\n", *anonymous);
    *anonymous = 42;
    printf("fun: now it's 42!\n");
}

int main() {
    int x = 1337;
    printf("main: x is initially %d\n", x);
    fun(&x);
    printf("main: x is now %d\n", x);
}
