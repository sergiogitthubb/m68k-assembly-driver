* ---------------------------------------------
* Inicio del programa y tabla de vectores
* ---------------------------------------------
    ORG $0
    DC.L $8000           * Puntero de pila (SP)
    DC.L MAIN            * Empezamos en MAIN

    ORG $400
* ---------------------------------------------
* Direcciones de los registros del DUART
* ---------------------------------------------
MR1A EQU $EFFC01
MR2A EQU $EFFC01
SRA  EQU $EFFC03
CSRA EQU $EFFC03
CRA  EQU $EFFC05
RBA  EQU $EFFC07
TBA  EQU $EFFC07
ACR  EQU $EFFC09
ISR  EQU $EFFC0B
IMR  EQU $EFFC0B
MR1B EQU $EFFC11
MR2B EQU $EFFC11
SRB  EQU $EFFC13
CSRB EQU $EFFC13
CRB  EQU $EFFC15
RBB  EQU $EFFC17
TBB  EQU $EFFC17
IVR  EQU $EFFC19

DESA  EQU 0              * Identificador para la linea A
DESB  EQU 1              * Identificador para la linea B
TAMBS EQU 30             * Cuantos leo de golpe
TAMBP EQU 7              * De cuantos en cuantos los escupo

* ---------------------------------------------
* Bucle principal de testeo
* ---------------------------------------------
MAIN:
    * Pongo manejadores por si la CPU casca, para que no muera en silencio
    MOVE.L #BUS_ERR,8
    MOVE.L #ADDR_ERR,12
    MOVE.L #ILL_INST,16
    MOVE.L #PRIV_VIO,32
    MOVE.L #ILL_INST,40
    MOVE.L #ILL_INST,44
    
    BSR INIT             * Configuro todo el hardware

    * Bajo el nivel a 0 para que entren las interrupciones
    MOVE.W #$2000,SR     

BUCLE_P:
    * --- Leo los datos de la A ---
    MOVE.W #TAMBS,PARTAM * Pido 30 caracteres
    MOVE.L #BUFFER,PARDIR * Y los guardo al principio del buffer

LEER_A:
    MOVE.W PARTAM,-(A7)  * Meto tamaño
    MOVE.W #DESA,-(A7)   * Meto puerto (A = 0)
    MOVE.L PARDIR,-(A7)  * Meto direccion
    BSR SCAN
    ADD.L #8,A7          * Saco parametros de la pila

    ADD.L D0,PARDIR      * Actualizo el puntero con lo que he leido
    SUB.W D0,PARTAM      * A ver cuantos me faltan por leer
    BNE LEER_A           * Si no he llegado a 30, sigo pidiendo

    * --- Imprimo los datos por la B ---
    MOVE.W #TAMBS,CONTC  * Voy a imprimir los 30 que acabo de leer
    MOVE.L #BUFFER,PARDIR * Vuelvo a poner el puntero al inicio
IMPR_B:
    MOVE.W #TAMBP,PARTAM * Los mando en paquetitos de 7

INTENTA:
    MOVE.W PARTAM,-(A7)  * Tamaño
    MOVE.W #DESB,-(A7)   * Puerto (B = 1)
    MOVE.L PARDIR,-(A7)  * Buffer
    BSR PRINT
    ADD.L #8,A7          * Limpio pila

    ADD.L D0,PARDIR      * Avanzo el puntero
    SUB.W D0,CONTC       * Resto lo que he conseguido imprimir
    BEQ SALIR            * Si ya no me queda nada, acabo

    SUB.W D0,PARTAM      * Si el PRINT me ha dejado a medias, ajusto
    BNE INTENTA          * y lo vuelvo a intentar con lo que sobra

    * Ajuste para el ultimo cacho (cuando quedan menos de 7)
    CMP.W #TAMBP,CONTC   
    BHI IMPR_B           * Si quedan bastantes, tiro normal
    MOVE.W CONTC,PARTAM  * Si quedan pocos, mando solo los que quedan
    BRA INTENTA          

SALIR:
    BRA BUCLE_P          * Vuelta a empezar el test

* ---------------------------------------------
* Funciones de E/S
* ---------------------------------------------

INIT:
    MOVE.B #$0,ACR
    MOVE.B #$CC,CSRA
    MOVE.B #$CC,CSRB
    MOVE.B #$03,MR1A
    MOVE.B #$00,MR2A
    MOVE.B #$03,MR1B
    MOVE.B #$00,MR2B
    MOVE.B #$40,IVR
    MOVE.B #$22,IMR
    MOVE.B #$22,IMR_COPY * Guardo la copia del IMR por si aca
    MOVE.B #$05,CRA
    MOVE.B #$05,CRB
    MOVE.L #RTI,$100     * Instalo mi RTI en el vector 64
    BSR INI_BUFS         * Llamada obligatoria a la libreria UPM
    RTS

SCAN:
    LINK A6,#0       
    CLR.L D1
    CLR.L D2
    MOVE.L 8(A6),A1      * Pillo la direccion
    MOVE.W 12(A6),D1     * Pillo el descriptor

    * Compruebo que el descriptor sea 0 o 1
    CMP.W #0,D1
    BEQ PAR_OK     
    CMP.W #1,D1
    BEQ PAR_OK
    BRA PAR_MAL      

PAR_OK:
    MOVE.W 14(A6),D2     * Saco el tamaño
    MOVE.L #0,D3         * Pongo mi contador a 0
    TST.L D2         
    BEQ FIN_LEC          * Si me piden tamaño 0, me largo

BUC_LEC:
    MOVE.L D1,D0     
    BSR LEECAR           * Leo un caracter

    CMP.L #-1,D0         * Si devuelve -1 es que esta vacio el buffer
    BEQ FIN_LEC 

    MOVE.B D0,(A1)+      * Lo guardo y avanzo puntero
    ADD.L #1,D3          * Sumo uno al contador
    SUB.L #1,D2          * Resto uno al tamaño que me pidieron
    BNE BUC_LEC

FIN_LEC:    
    MOVE.L D3,D0         * Devuelvo lo leido en D0
    UNLK A6
    RTS

PAR_MAL:
    MOVE.L #$FFFFFFFF,D0 * Devuelvo -1 de error
    UNLK A6
    RTS

PRINT:
    LINK A6,#0
    CLR.L D2
    CLR.L D3
    
    MOVE.L 8(A6),A1      * Puntero al buffer
    MOVE.W 12(A6),D2     * Descriptor
    CMP.W #1,D2
    BEQ PRINT_OK     
    CMP.W #0,D2
    BEQ PRINT_OK
    BRA ERR_PRNT     

PRINT_OK:
    MOVE.W 14(A6),D3     * Tamaño
    MOVE.L #0,D4         * Contador de escritos a 0
    TST.W D3         
    BEQ FIN_ESC          * Si me piden 0, no hago nada

BUC_ESC:
    MOVE.B (A1)+,D1      * Pillo caracter del buffer
    MOVE.L D2,D0
    ADD.L #2,D0          * Sumo 2 para que sea buffer de transmision
        
    BSR ESCCAR
        
    CMP.L #$FFFFFFFF,D0 
    BEQ LLENO            * Si me da -1 es que el buffer esta a tope

    ADD.L #1,D4          * Sumo al contador
    CMP.L #0,D2 
    BEQ HAB_TA           * Si es A, habilito tx de A
    BRA HAB_TB           * Si no, la de B

LLENO:
    SUB.L #1,A1          * Tiro pa atras el puntero para no perder la letra
    BRA FIN_ESC          * Y me salgo

HAB_TA:
    MOVE.W SR,-(A7)      * Guardo SR (Seccion critica)
    ORI.W  #$0700,SR     * Corto interrupciones para que no me machaquen
    BSET #0,IMR_COPY     * Enciendo transmision A
    MOVE.B IMR_COPY,IMR
    MOVE.W (A7)+,SR      * Restauro SR
    BRA FIN_HAB

HAB_TB:
    MOVE.W SR,-(A7)      * Guardo SR
    ORI.W  #$0700,SR     * Corto interrupciones
    BSET #4,IMR_COPY     * Enciendo transmision B
    MOVE.B IMR_COPY,IMR
    MOVE.W (A7)+,SR      

FIN_HAB:
    SUB.L #1,D3          * Ya he metido uno, a ver si quedan mas
    BNE BUC_ESC

FIN_ESC:
    MOVE.L D4,D0         * Devuelvo en D0 los que he metido
    UNLK A6
    RTS

ERR_PRNT:
    MOVE.L #$FFFFFFFF,D0
    UNLK A6
    RTS

RTI:
    MOVEM.L D0-D7/A0-A6,-(A7) * Salvo todos los registros

    CLR.L D2
    MOVE.B ISR,D2
    
    * Chequeo si es recepcion de A
    BTST #1,D2
    BEQ MIRA_B       

    CLR.L D0         
    CLR.L D1         
    MOVE.B RBA,D1        * Leo de la linea A
    MOVE.L #0,D0         * Buffer de recepcion A
    BSR ESCCAR

MIRA_B:
    * Chequeo si es recepcion de B
    BTST #5,D2
    BEQ MIRA_TA
    
    CLR.L D0 
    CLR.L D1 
    MOVE.B RBB,D1        * Leo de la linea B
    MOVE.L #1,D0         * Buffer de recepcion B
    BSR ESCCAR

MIRA_TA:
    * Chequeo si es transmision de A
    BTST #0,D2
    BEQ MIRA_TB

    MOVE.L #2,D0         * A ver si hay algo en el buffer de tx
    BSR LEECAR
    CMP.L #-1,D0
    BEQ CORTA_TA         * Si esta vacio, apago la interrupcion
    MOVE.B D0,TBA        * Si hay, lo escupo a la linea
    BRA MIRA_TB          * Y sigo mirando por si hay de la B

CORTA_TA:
    BCLR #0,IMR_COPY
    MOVE.B IMR_COPY,IMR
    
MIRA_TB:
    * Chequeo si es transmision de B
    BTST #4,D2
    BEQ FIN_RTI
    MOVE.L #3,D0
    BSR LEECAR
    CMP.L #-1,D0
    BEQ CORTA_TB         
    MOVE.B D0,TBB
    BRA FIN_RTI

CORTA_TB:
    BCLR #4,IMR_COPY
    MOVE.B IMR_COPY,IMR
    
FIN_RTI:
    MOVEM.L (A7)+,D0-D7/A0-A6 * Restauro registros
    RTE

* ---------------------------------------------
* Variables y memoria
* ---------------------------------------------
IMR_COPY: DC.W $0000     * Copia del IMR (pongo .W para alinear par)

BUFFER:   DS.B 2100      * Mi cacho de memoria
PARDIR:   DC.L 0         
PARTAM:   DC.W 0         
CONTC:    DC.W 0         

* Control de cuelgues raros
BUS_ERR:  BREAK
          NOP
ADDR_ERR: BREAK
          NOP
ILL_INST: BREAK
          NOP
PRIV_VIO: BREAK
          NOP

    INCLUDE bib_aux.s
    