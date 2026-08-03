#include <stdio.h>

static int add_numbers(int a, int b) {
    return a + b;
}

int main(void) {
    printf("Result: %d\n", add_numbers(20, 22));
    return 0;
}
