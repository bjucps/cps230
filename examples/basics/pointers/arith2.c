#include <stdio.h>

int main() {
    int arr[] = { 1, 2, 3, 4, 5 };

    printf("arr[4] is %zd elements away from arr[1]\n", 
        &arr[4] - &arr[1]);
    printf("arr[4] is %zd bytes away from arr[1]\n", 
        (char *)&arr[4] - (char *)&arr[1]);

    return 0;
}
