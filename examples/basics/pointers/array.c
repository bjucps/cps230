#include <stdio.h>

void takes_array(int array[]) {
    printf("array starts at %p and is %zu bytes long\n", array, sizeof array);
}

int main() {
    int arr[5] = { 2, 3, 5, 7, 11 };
    printf("arr starts at %p and is %zu bytes long\n", &arr, sizeof arr);
    takes_array(arr);
    return 0;
}
