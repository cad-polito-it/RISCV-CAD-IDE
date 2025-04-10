#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

int main(int argc, char* argv[]){

    uint32_t a = 10, b = 5, result;

    asm volatile(
        "sub %0, %1, %2"
        : "=r" (result)
        : "r" (a), "r" (b)
    );

    printf("il risultato di %" PRIu32 " - %" PRIu32 " = %" PRIu32 "\n", a, b, result);

    return 0;
}