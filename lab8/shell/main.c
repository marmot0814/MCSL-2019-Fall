#include "inc/stm32l476xx.h"

char* prev;
char* strtok(char *str) {
    if (str)
        prev = str;
    else
        str = prev;
    if (*str == '\0')
        return 0;
    while (*prev != '\0' && *prev != ' ')
        prev++;
    while (*prev == ' ')
        *prev = '\0', prev++;
    return str;
}

int strlen(char *s) {
    int ret = 0;
    while (*s != '\0')
        s++, ret++;
    return ret;
}

int strcmp(char *a, char *b) {
    int lenA = strlen(a);
    int lenB = strlen(b);
    if (lenA != lenB)
        return 0;
    for (int i = 0 ; i < lenA ; i++)
        if (a[i] != b[i])
            return 0;
    return 1;
}

// use this pragma at handlers
//#pragma thumb

int main() {
	return 0;
}
