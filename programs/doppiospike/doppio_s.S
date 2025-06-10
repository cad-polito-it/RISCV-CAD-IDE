.section .text      # .text specifica la parte di testo separata dai dati .data
.global add_numbers # .global rende la funzione globale visibile e utilizzabile da altri programmi

add_numbers:
    add a0, a0, a1  # add fa la somma tra registri a0, a1 e lo inserisce in a0
    ret             # ret ritorna al chiamante ed è l'abbreviazione di jalr x0, 0(x1)
                    # dove x1 è il registro che contiene l'indirizzo di ritorno