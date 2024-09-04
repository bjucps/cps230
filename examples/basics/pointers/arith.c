#include <stdio.h>

int main() {
    int arr[] = { 1, 2, 3, 4, 5 };
    printf("arr[2] = %d\n", arr[2]);
    printf("arr[2] = %d\n", *(arr + 2));    // arr[2] is shorthand for *(arr + 2)
    printf("arr[2] = %d\n", *(2 + arr));    // + is commutative, right?
    printf("arr[2] = %d\n", 2[arr]);        // O_O!!!! (not recommended for production code)
    return 0;
}
