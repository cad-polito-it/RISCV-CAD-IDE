    .section .text
    .global subtract   # Rendi la funzione visibile per il C

subtract:
    # Carica 10 nel registro t0
    li t0, 0xA        # Carica l'upper immediate di 10 in t0 (10 è 0xA)
    addi t0, t0, 0     # Aggiungi 0 per completare il valore (lohi + 0)

    # Carica 5 nel registro t1
    li t1, 0x5        # Carica l'upper immediate di 5 in t1
    addi t1, t1, 0     # Aggiungi 0 per completare il valore (lui + 0)

    # Esegui la sottrazione t0 - t1 e memorizza il risultato in t2
    sub t2, t0, t1

    # Prepara per stampare il risultato
    mv a0, t2         # Copia il risultato della sottrazione in a0 (registro per il valore da stampare)
#    li a7, 1          # Codice della syscall per stampare un intero
#    ecall             # Esegui la syscall
    ret               # Ritorna dalla funzione
