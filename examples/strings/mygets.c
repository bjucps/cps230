#include <stdio.h>
#include <string.h>

char *mygets(char *buff, size_t space) {
    char c;
    int i = 0;
    
    --space;
    while (i < space) {
        c = getchar();
        if ((c == EOF) || (c == '\n')) break;
        buff[i] = c;
        ++i;
    }
    buff[i] = '\0';
    return buff;
}

int main() {
    char line[10] = "";
    mygets(line, sizeof line);
    printf("hello, %s!\n", line);
    return 0;
}