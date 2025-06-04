#include <stdio.h>
#include <stdint.h>

extern uint32_t add_numbers(uint32_t, uint32_t); // dichiara la funzione esterna assembly che riceve 
                                                 // due interi 32bit e ne restituisce uno a sua volta
extern uint32_t subtract(void);

int main() {

    uint32_t a = 10, b = 30, result;
    
    result = add_numbers(a, b); // chiamata a funzione che ritorna il risultato

    printf("Risultato di %u + %u = %u \n", a, b, result);

    result = subtract();
    printf("risultato %u\n", result);
    return 0;
}

// questo file andrà compilato e assemblato in oggetto come riscv64-unknown-elf-gcc -c main.c -o main.o 
// il file.s va assemblato come riscv64-unknown-elf-as functions.s -o functions.o 
// una volta assemblato il file .s vanno linkati : riscv64-unknown-elf-gcc -o my_program main.o functions.o