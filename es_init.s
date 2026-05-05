
MR1A EQU $EFFC01
MR2A EQU $EFFC01
SRA EQU $EFFC03
CSRA EQU $EFFC03
CRA EQU $EFFC05
RBA EQU $EFFC07
TBA EQU $EFFC07
ACR EQU $EFFC09
ISR EQU $EFFC0B
IMR EQU $EFFC0B
MR1B EQU $EFFC11
MR2B EQU $EFFC11
SRB EQU $EFFC13
CSRB EQU $EFFC13
CRB EQU $EFFC15
RBB EQU $EFFC17
TBB EQU $EFFC17
IVR EQU $EFFC19

    ORG $400


* Rutina de Inicialización

INIT:
    *Velocidad adecuada ambas lineas
    MOVE.B #$0, ACR
    MOVE.B #$CC, CSRA
    MOVE.B #$CC, CSRB
    *8 bits por carácter y modo normal en ambas líneas
    MOVE.B #$03, MR1A
    MOVE.B #$00, MR2A
    MOVE.B #$03, MR1B
    MOVE.B #$00, MR2B
    *Vector de interrupción 40
    MOVE.B #$40, IVR
    *Ajuste mascara interrupción para recepción y transmisión
    MOVE.B #$22, IMR
    *Habilitar transmision y recepcion
    MOVE.B #$05, CRA
    MOVE.B #$05, CRB
    *Actualización dirección de RTI tabla de vectores
    MOVE.L #RTI, $100
    BSR INI_BUFS

    RTS

* ---------------------------------------------------------
* Rutina de Lectura (No bloqueante)
* ---------------------------------------------------------
SCAN:

    LINK A6, #0 *Anclaje en A6 para parámetros
    CLR.L D1
    CLR.L D2
    MOVE.L 8(A6), A1 * Buffer
    MOVE.W 12(A6), D1 * Descriptor

    CMP.W #0, D1
    BEQ PARAMETROS_OK
     CMP.W #1, D1
    BEQ PARAMETROS_OK
    BRA ERROR_PARAMETROS * Si llega aquí, es que no es ni 0 ni 1 el descriptor
    PARAMETROS_OK:
    MOVE.W 14(A6), D2 * Tamaño
    MOVE.L #0, D3 * Contador inicializado a 0
    TST.L D2 *Testeo por si el tamaño es 0, si lo es salta al final del bucle de lectura
    BEQ FIN_LECTURA

    BUCLE_LECTURA:
        MOVE.L D1, D0 *Paso descriptor a leecar en D0
        BSR LEECAR 

        CMP.L #-1, D0 *Asegurarnos de que siguen quedando caracteres en el buffer interno
        BEQ FIN_LECTURA 

        

        MOVE.B D0, (A1)+ *Guardamos el caracter en  Buffer
        ADD.L #1, D3 *Incrementamos el contador en 1

        SUB.L #1, D2 *Restamos uno a tamaño y lo comparamos con 0 si no es igual, volvemos a iterar BUCLE_LECTURA
        BNE BUCLE_LECTURA
    FIN_LECTURA:    
    MOVE.L D3, D0
    UNLK A6
    RTS
    ERROR_PARAMETROS:
        MOVE.L #$FFFFFFFF, D0
        UNLK A6
        RTS



* ---------------------------------------------------------
* Rutina de Escritura (No bloqueante)
* ---------------------------------------------------------
PRINT:
    * (Aquí irá la lógica de escritura)
    RTS

* ---------------------------------------------------------
* Rutina de Tratamiento de Interrupciones (RTI)
* ---------------------------------------------------------
RTI:
    * (Aquí gestionaremos quién llamó a la puerta)
    RTE






INCLUDE bib_aux.s       * Funciones auxiliares de la UPM
    

