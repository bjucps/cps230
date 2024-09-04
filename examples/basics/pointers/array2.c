#include <stdio.h>

long long takes_array2(int *arr, size_t len) {
    long long sum = 0;
    for (int i = 0; i < len; ++i) {
        sum += arr[i];
    }
    return sum;
}

int main() {
    int data[] = { 2, 3, 5, 7, 11, 13 };
    printf("the sum of our array is %lld\n", takes_array2(data, sizeof data / sizeof data[0]));
    return 0;
}
