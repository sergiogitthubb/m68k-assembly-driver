* =================================================================
* SECCIÓN 1: TABLA DE VECTORES (Direcciones $0 a $3FF)
* =================================================================
    ORG $0
    DC.L $8000              * Puntero de pila inicial (SSP)
    DC.L START              * PC inicial (donde empieza el código)

    ORG $100                * Vector 40 (Hex): $40 * 4 = $100
    DC.L RTI                * Dirección de la rutina de interrupción

* =================================================================
* SECCIÓN 2: PROGRAMA PRINCIPAL Y DATOS (A partir de $400)
* =================================================================
    ORG $400

START:
    * 1. Configuración de manejadores de excepciones (Opcional pero recomendado)
    * (Aquí podrías copiar el código de la pág. 76 para depurar errores)

    * 2. Inicialización del sistema
    BSR INIT                * Llama a tu rutina de configuración
    MOVE.W #$2000, SR       * Habilita interrupciones en el micro (Nivel 0)

BUCLE_PRINCIPAL:
    * Aquí irá tu código de prueba (ej: el de las páginas 75-76)
    * Por ahora, un bucle infinito para que no se "escape" el micro:
    BRA BUCLE_PRINCIPAL

* =================================================================
* SECCIÓN 3: SUBRUTINAS OBLIGATORIAS
* =================================================================

INIT:
    INIT:
    LINK A6,#0            * Crea el marco de pila para variables locales
    
    * 1. Inicializar los buffers internos
    BSR INI_BUFS          * Llama a la rutina de la biblioteca para limpiar colas

    * 2. Configurar la DUART MC68681 (Línea A)
    * OJO: Se usa MOVE.B porque los registros de la DUART son de 8 bits
    MOVE.B #$13, $EFFC01  * MR1A: 8 bits/carácter y avisa al recibir (RxRDY)
    MOVE.B #$07, $EFFC01  * MR2A: Modo normal, sin eco automático
    MOVE.B #$80, $EFFC09  * ACR: Selecciona el Conjunto 2 de velocidades
    MOVE.B #$CC, $EFFC03  * CSRA: Velocidad a 38400 bps (tanto en Tx como Rx)
    MOVE.B #$40, $EFFC19  * IVR: Le decimos que use el vector de interrupción $40
    MOVE.B #$02, $EFFC0B  * IMR: Habilita SOLO el aviso de recepción (RxRDY) por ahora
    MOVE.B #$05, $EFFC05  * CRA: Habilita el transmisor y el receptor para empezar

    * 3. Permitir que el microprocesador escuche las interrupciones
    MOVE.W #$2000, SR     * Pone la máscara del SR a nivel 0 (escucha todo)

    UNLK A6               * Destruye el marco de pila
    RTS                   * Vuelve al programa principal

SCAN:
    LINK A6,#0
    * --- Tu código aquí (usando LEECAR) ---
    UNLK A6
    RTS

PRINT:
    LINK A6,#0
    * --- Tu código aquí (usando ESCCAR) ---
    UNLK A6
    RTS

RTI:
    * --- Tu rutina de interrupción ---
    * 1. Salvar registros: MOVEM.L D0-D7/A0-A6,-(A7)
    * 2. Gestionar interrupción
    * 3. Restaurar registros: MOVEM.L (A7)+,D0-D7/A0-A6
    RTE                     * Fin de interrupción (¡No usar RTS!)

* =================================================================
* SECCIÓN 4: INCLUSIÓN DE BIBLIOTECAS
* =================================================================
    INCLUDE bib_aux.s       * Funciones auxiliares de la UPM
    
* ¡IMPORTANTE! Deja al menos una línea vacía aquí abajo
