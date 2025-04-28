; MSP430FR6989 - Encender LEDs mientras se mantiene presionado S1 o S2
; S1 (P1.1) controla LED rojo (P1.0)
; S2 (P1.2) controla LED verde (P9.7)
; last update 4/26/2025
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"


            .text
            .def    RESET
;-------------------------------------------------------------------------------

pos1	.equ	9      ; Alphanumeric A1 begins at S18
pos2	.equ	5      ; Alphanumeric A2 begins at S10
pos3 	.equ	3      ; Alphanumeric A3 begins at S6
pos4 	.equ	18     ; Alphanumeric A4 begins at S36
pos5	.equ	14     ; Alphanumeric A5 begins at S28
pos6 	.equ	7      ; Alphanumeric A6 begins at S14

; Define high and low byte values to generate chars A, N, G, E, L, I, C, A
; angelica              T     E     A     M     0      3  space space space   A     N     G     E     L     I     C     A   space  space space  C     A     M     I     L    A    space  space space  I      S    A     N      D    E     R   space  space space  E     D      G     A    R     D     O    space space space 
stringNamesH	.byte 0x80, 0x9F, 0xEF, 0x6C, 0xFC, 0xF3, 0x00, 0x00, 0x00, 0xEF, 0x6C, 0xBD, 0x9F, 0x1C, 0x90, 0x9C, 0xEF, 0x00, 0x00, 0x00, 0x9C, 0xEF, 0x6C, 0x90, 0x1C, 0xEF, 0x00, 0x00, 0x00, 0x90, 0xB7, 0xEF, 0x6C, 0xF0, 0x9F, 0xCF, 0x00, 0x00, 0x00, 0x9F, 0xF0, 0xBD, 0xEF, 0xCF, 0xF0, 0xFC, 0x00, 0x00, 0x00, 0x80, 0x9F, 0xEF, 0x6C, 0xFC, 0xF3
stringNamesL	.byte 0x50, 0x00, 0x00, 0xA0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x82, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x82, 0x50, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x02, 0x50, 0x00, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0xA0, 0x00, 0x00

    
RESET:
            mov.w   #__STACK_END, SP          ; Inicializa el stack
            mov.w   #WDTPW | WDTHOLD, &WDTCTL ; Detiene Watchdog

            ;----------------------------
            ; CONFIGURACIÓN DE LEDs
            ;-----------------------------
            CALL    #Init_LEDS
            CALL    #Init_Buttons           ; CONFIGURACIÓN DE BOTONES S1 y S2
            CALL    #Init_LCD
            CALL    #Init_Display
            CALL    #Init_REgisters
            CALL    #Init_Interruptions

            bic.w   #LOCKLPM5, &PM5CTL0       ; Desbloquea GPIOs

            nop
            bis.w   #GIE, SR                  ; Habilita interrupciones globales
            nop


;=============================================================
;                       Main Loop
;=============================================================
;
;
;
;
;----------
MAIN_LOOP:
   
    cmp     #3, R8      ; estamos en el input number screen
    jeq     Blink_at_CurrentIndex

    cmp.b   #1, R11
    jne     Saltar_Desplazamiento
    CALL    #Desplazamiento
    CALL    #Delay_500ms


Saltar_Desplazamiento:
    jmp     MAIN_LOOP



;===========================================================================
;    Inits Individuales
;===========================================================================
;
;
;----------
;
;
;
;--------
Init_LEDS
    bis.b   #BIT0, &P1DIR             ; P1.0 como salida (LED rojo)
    bic.b   #BIT0, &P1OUT             ; Apagado al inicio

    bis.b   #BIT7, &P9DIR             ; P9.7 como salida (LED verde)
    bic.b   #BIT7, &P9OUT             ; Apagado al inic
    RET
;----------------
;
;
;----------------
Init_Interruptions:
    bic.b   #BIT1 + BIT2, &P1IFG     ; Limpia banderas previas
    bis.b   #BIT1 + BIT2, &P1IES     ; Flanco de bajada
    bis.b   #BIT1 + BIT2, &P1IE      ; Habilita interrupciones
    RET

Init_Buttons
; CONFIGURACIÓN DE BOTONES S1 y S2
    bis.b   #BIT1 + BIT2, &P1REN      ; Habilita resistencia en P1.1 y P1.2
    bis.b   #BIT1 + BIT2, &P1OUT      ; Pull-up activado

    bic.b   #BIT1 + BIT2, &P1DIR      ; P1.1 y P1.2 como entrada
    RET

Init_REgisters:             ; anadir aqui todos los registros que usamos
    mov     #0, R6
    mov     #0, R8
    mov     #0, R9
    mov     #0, R10
    mov     #0, R11
    mov     #0, R12
    mov     #0, R15 
    ret

Init_LCD
    MOV.W   #0xFFFF,&LCDCPCTL0  ; Initialize LCD segments 0 - 21; 26 - 43
    MOV.W   #0xFC3F,&LCDCPCTL1
    MOV.W   #0x0FFF,&LCDCPCTL2
   
    MOV.W   #0x041E,&LCDCCTL0   ; Initialize LCD_C
    MOV.W   #0x0208,&LCDCVCTL
    MOV.W   #0x8000,&LCDCCPCTL  
    MOV.W   #2,&LCDCMEMCTL      

    BIS.W   #1,&LCDCCTL0        ; Turn LCD on
    RET

Init_Display:
    MOV.B   #0, R6
    CALL    #Actualiza_Display

    RET
;========================================================================================
;                                        Variables
;======================================================================================

;   R4 = modo
;   R5 = freq
;   R6 = Input number
;   R7 = division ratio
;   R8 = screen
;   R9 = index del input number
;   R10 = helper scroll digits 0-9
;   R11 = boton 1 Presionado Flag
;   R12 = 
;   R13 = helper scroll digits 0-4
;   R14 = helper
;   R15 = helper delay clock, 0


;=================================================================================================
;       Interrupcion
;=================================================================================================

PORT1_ISR:
    ; ========== S1 (P1.1) ==========
    bit.b   #BIT1, &P1IFG
    jz      check_S2
    bic.b   #BIT1, &P1IFG             ; Limpia bandera

    bit.b   #BIT1, &P1IN
    jnz     s1_subida                 ; Si P1.1 está en HIGH, es subida
    jmp     s1_bajada                 ; Si p1.1 esta low, es bajada


s1_subida:  
    bic.b   #BIT0, &P1OUT             ; Apaga LED rojo
    mov.b   #0, R11                     ; Bandera en 0
    bis.b   #BIT1, &P1IES             ; Próxima interrupción: bajada
    jmp     fin_ISR


s1_bajada:
     CALL    #Delay_500ms               ; debouncing
    cmp.b   #0, R8
    jeq     screen0_s1_bajada

    cmp.b   #1, R8
    jeq     screen1_s1_bajada

    cmp.b   #2, R8
    jeq     screen2_s1_bajada

    cmp.b   #3, R8
    jeq     screen3_s1_bajada

    cmp.b   #4, R8
    jeq     screen4_s1_bajada

    cmp.b   #5, R8
    jeq     screen5_s1_bajada
    
    jmp     fin_ISR


screen0_s1_bajada:                        ; Screen inicicial
    mov.b   #1, R11
    bis.b   #BIT0, &P1OUT
    bic.b   #BIT1, &P1IES
    jmp     fin_ISR

screen1_s1_bajada:                          ;   Menu
    mov.b   #0, R8
    mov.b   #1, R11
    bis.b   #BIT0, &P1OUT
    bic.b   #BIT1, &P1IES
    jmp     fin_ISR

screen2_s1_bajada:                          ;   Mode
    bis.b   #BIT0, &P1OUT
    CALL    #Incrementar_Digito_Modo
    CALL    #DisplayDigit_en_A6
    jmp     fin_ISR

screen3_s1_bajada:                          ;   Input Number
    bis.b   #BIT0, &P1OUT
    CALL    #Increment_Display_Digit
    CALL    #Get_7Segment_Code
    CALL    #Display_at_index
    CALL    #Guardar_InputNumber
    jmp     fin_ISR

screen4_s1_bajada:                         ; Frequency
    bis.b   #BIT0, &P1OUT
    CALL    #Incrementar_Digito_Freq
    CALL    #DisplayDigit_en_A6
    jmp     fin_ISR

screen5_s1_bajada:                         ; Div Frequency
    bis.b   #BIT0, &P1OUT
    CALL    #Incrementar_Digito_DivFreq
    CALL    #DisplayDigit_en_A6
    jmp     fin_ISR
                                            

; ========== S2 (P1.2) ==========

check_S2:
    bit.b   #BIT2, &P1IFG
    jz      fin_ISR
    bic.b   #BIT2, &P1IFG

    bit.b   #BIT2, &P1IN
    jnz     s2_subida
    jmp     s2_bajada

s2_subida:
    bic.b   #BIT7, &P9OUT             ; Apaga LED verde
    bis.b   #BIT2, &P1IES             ; Próxima interrupción: bajada
    mov.b   #0, R11                     ; Bandera en 0
    jmp     fin_ISR

s2_bajada:
    CALL    #Delay_500ms

    cmp.b   #0, R8
    jeq    screen0_s2_bajada

    cmp.b   #1, R8
    jeq     screen1_s2_bajada

    cmp.b   #2, R8
    jeq     screen2_s2_bajada

    cmp.b   #3, R8
    jeq     screen3_s2_bajada

    cmp.b   #4, R8
    jeq     screen4_s2_bajada

    cmp.b   #5, R8
    jeq     screen5_s2_bajada

    jmp     fin_ISR


screen0_s2_bajada:                             ; inicio
    bis.b   #BIT7, &P9OUT
    mov.b   #1, R8
    CALL    #Display_Menu
    bic.b   #BIT2, &P1IES
    jmp     fin_ISR

screen1_s2_bajada:                            ; Menu
    bis.b   #BIT7, &P9OUT
    MOV.B   #2, R8
    CALL    #Display_Modo
    CALL    #DisplayDigit_en_A6
    jmp     fin_ISR


screen2_s2_bajada:                           ; modo
    bis.b   #BIT7, &P9OUT
    MOV.B   #3, R8
    CALL    #Display_Initial_InputNumber
    CALL    #Guardar_MODO_Seleccionado
    jmp     fin_ISR


screen3_s2_bajada:                          ; input number
    mov     #1, R12
    bis.b   #BIT7, &P9OUT
    CALL    #Incrementar_InputNumber_Index

    cmp     #6,R9
    JEQ     cambiar_screen
    jmp     fin_ISR
   
cambiar_screen:
    MOV.B   #4, R8
    mov     #0, R9
    mov     #0, R13         ;reset digit index
    CALL    #Display_FREQ
    CALL    #DisplayDigit_en_A6
    jmp     fin_ISR

screen4_s2_bajada:
    bis.b   #BIT7, &P9OUT
    MOV.B   #5, R8
    CALL    #Guardar_FREQ_Seleccionada
    CALL    #Display_DIVFREQ
    CALL    #DisplayDigit_en_A6
    jmp     fin_ISR

screen5_s2_bajada:
    bis.b   #BIT7, &P9OUT
    MOV.B   #6, R8
    CALL    #Guardar_DIVFreq_Seleccionada
    CALL    #Display_Ready
    jmp     fin_ISR

fin_ISR:
    reti


;==============================================================================================
; Subrutinas para hacer dsiplay al LCD
;=================================================================================================
    

Display_Ready:
            MOV.B   #0xCF, &0xA29           ; "R" at A1
            MOV.B   #0x02, &0xA2A

            MOV.B   #0x9F, &0xA25           ; "E" at A2
            MOV.B   #0x00, &0xA26

            MOV.B   #0xEF, &0xA23           ; "A" at A3
            MOV.B   #0x00, &0xA24

            MOV.B   #0xF0, &0xA32           ; "D" at A4
            MOV.B   #0x50, &0xA33

            MOV.B   #0x00, &0xA2E           ; "Y" at A5
            MOV.B   #0xB0, &0xA2F

            MOV.B   #0x00, &0xA27
            MOV.B   #0x00, &0xA28

            MOV.B   #0x10, &0xA31           ;Turn on battery brackets 
            MOV.B   #0x08, &0xA22           ;Turn on timer icon 

            RET

Display_Menu:
            ;Mov.B #1, &screen
            MOV.B   #0x6C, &0xA29               ; "M" at A1
            MOV.B   #0xA0, &0xA2A

            MOV.B   #0x9F, &0xA25               ; "E" at A2
            MOV.B   #0x00, &0xA26 

            MOV.B   #0x6C, &0xA23               ; N at A3
            MOV.B   #0x82, &0xA24

            MOV.B   #0x7c, &0xA32               ; U at A4
            MOV.B   #0x00, &0xA33

            MOV.B   #0x00, &0xA2E          
            MOV.B   #0x00, &0xA2F

            MOV.B   #0x00, &0xA27
            MOV.B   #0x00, &0xA28

            RET   

Display_Modo 
            MOV.B   #0x6C, &0xA29       ; "M" at A1
            MOV.B   #0xA0, &0xA2A
            MOV.B   #0xFC, &0xA25       ; "O" at A2
            MOV.B   #0xF0, &0xA23       ; "D" at A3
            MOV.B   #0x50, &0xA24
            MOV.B   #0x9F, &0xA32       ; "E" at A4
            MOV.B   #0x10, &0xA2E       ; "_" at A5
            MOV.B   #0x00, &0xA27       ; at A6
            RET   

Display_Initial_InputNumber
            MOV.B   #0x9C, &0xA29       ; "C" at A1
            MOV.B   #0x00, &0xA2A
            MOV.B   #0xFC, &0xA25       ; "0" at A2
            MOV.B   #0x00, &0xA26
            MOV.B   #0xFC, &0xA23       ; "0" at A3
            MOV.B   #0x00, &0xA24
            MOV.B   #0xFC, &0xA32       ; "0" at A4
            MOV.B   #0x00, &0xA33
            MOV.B   #0xFC, &0xA2E       ; "0" at A5
            MOV.B   #0x00, &0xA2F
            MOV.B   #0xFC, &0xA27       ; "0" at A6
            MOV.B   #0x00, &0xA28
            RET  

Display_FREQ 
            MOV.B   #0x8F, &0xA29               ; "F" at A1
            MOV.B   #0x00, &0xA2A

            MOV.B   #0xCF, &0xA25               ; "R" at A2
            MOV.B   #0x02, &0xA26 

            MOV.B   #0x9F, &0xA23               ; E at A3
            MOV.B   #0x00, &0xA24

            MOV.B   #0xFC, &0xA32               ; Q at A4
            MOV.B   #0x82, &0xA33

            MOV.B   #0x10, &0xA2E               ; _ at A5
            MOV.B   #0x00, &0xA2F

            MOV.B   #0x00, &0xA27               ; 0 at A6
            MOV.B   #0x00, &0xA28

            RET

Display_DIVFREQ 
            MOV.B   #0x8F, &0xA29               ; "F" at A1
            MOV.B   #0x00, &0xA2A

            MOV.B   #0xCF, &0xA25               ; "R" at A2
            MOV.B   #0x02, &0xA26 

            MOV.B   #0xFC, &0xA23               ; "Q" at A3
            MOV.B   #0x82, &0xA24

            MOV.B   #0x00, &0xA32               ; "/" at A4
            MOV.B   #0x28, &0xA33

            MOV.B   #0x10, &0xA2E               ; _ at A5
            MOV.B   #0x00, &0xA2F

            MOV.B   #0xFC, &0xA27               ; 0 at A6
            MOV.B   #0x00, &0xA28

            RET 
;
; Esta subrutina se encarga de hacer display en un solo index y la usamos para seleccionar modo y freq
; Creo que la podemos sustituir usando display at index
;
DisplayDigit_en_A6:
    CMP     #0, R13
    JEQ     Digit0_To_Display

    CMP     #1, R13
    JEQ     Digit1_To_Display

    CMP     #2, R13
    JEQ     Digit2_To_Display

    CMP     #3, R13
    JEQ     Digit3_To_Display

    CMP     #4, R13
    JEQ     Digit4_To_Display

    CMP     #5, R13
    JEQ     Digit5_To_Display

    CMP     #6, R13
    JEQ     Digit6_To_Display

    CMP     #7, R13
    JEQ     Digit7_To_Display
    
    ret

Digit0_To_Display:
    mov.b   #0xFC, &0xA27       ; Segmentos para 0 en A6
    mov.b   #0x00, &0xA28
    ret

Digit1_To_Display:
    mov.b   #0x60, &0xA27       ; Segmentos para 1 en A6
    mov.b   #0x20, &0xA28
    ret

Digit2_To_Display:
    mov.b   #0xDB, &0xA27       ; Segmentos para 2 en A6
    mov.b   #0x00, &0xA28
    ret

Digit3_To_Display:
    mov.b   #0xF1, &0xA27       ; Segmentos para 3 en A6
    mov.b   #0x00, &0xA28
    ret

Digit4_To_Display:
    mov.b   #0x67, &0xA27       ; Segmentos para 4 en A6
    mov.b   #0x00, &0xA28
    ret

Digit5_To_Display:
    mov.b   #0xB7, &0xA27       ; Segmentos para 5 en A6 mal
    mov.b   #0x00, &0xA28
    ret

Digit6_To_Display:
    mov.b   #0xBF, &0xA27       ; Segmentos para 6 en A6
    mov.b   #0x00, &0xA28
    ret

Digit7_To_Display:
    mov.b   #0xE0, &0xA27       ; Segmentos para 7 en A6
    mov.b   #0x00, &0xA28
    ret


Increment_Display_Digit;
    INC     R13
    ret

Incrementar_Digito_Modo:
    INC     R13
    cmp     #5, R13
    jeq     reset_Digito
    ret

Incrementar_Digito_Freq:
    INC     R13
    cmp     #8, R13
    jeq     reset_Digito
    ret

Incrementar_Digito_DivFreq:
    INC     R13
    cmp     #6, R13
    jeq     reset_Digito
    ret

reset_Digito:
    mov     #0, R13
    ret
;====================================================================================================================
;               Guardar
;====================================================================================================================
;
; aqui setiamos el registro R4 quien guarda el modo seleccionado y hacemos reset de el index del digito

Guardar_MODO_Seleccionado:
    MOV     R13, R4
    MOV      #0, R13
    RET

Guardar_FREQ_Seleccionada:
    MOV     R13, R5
    MOV      #0, R13
    RET

Guardar_DIVFreq_Seleccionada:
    MOV     R13, R7
    MOV      #0, R13
    RET

; Subrutina para guardar el dígito ingresado en R6 según su posición
Guardar_InputNumber:
    ; Guardar registros usados temporalmente
    push    R14
    push    R15

    ; Validar que R13 esté en el rango 0-9
    cmp     #10, R13
    jge     End_Guardar_InputNumber

    ; Verificar el índice actual (R9) para determinar la potencia de 10
    cmp     #0, R9
    jeq     Pos_10000
    cmp     #1, R9
    jeq     Pos_1000
    cmp     #2, R9
    jeq     Pos_100
    cmp     #3, R9
    jeq     Pos_10
    cmp     #4, R9
    jeq     Pos_1

    ; Si R9 no es válido, salir
    jmp     End_Guardar_InputNumber

Pos_10000:
    ; Calcular R13 * 10000
    mov     R13, R14        ; Copiar dígito a R14
    mov     #0, R15         ; Acumulador para el resultado
    mov     #10, R12        ; Contador para 10 iteraciones (para *1000)
    call    #Calc_1000      ; R15 = R13 * 1000
    mov     R15, R14        ; Copiar resultado intermedio
    mov     #0, R15         ; Reiniciar acumulador
    mov     #10, R12        ; Contador para 10 iteraciones (para *10)
    call    #Calc_10        ; R15 = (R13 * 1000) * 10 = R13 * 10000
    add     R15, R6         ; Sumar a R6
    jmp     End_Guardar_InputNumber

Pos_1000:
    ; Calcular R13 * 1000
    mov     R13, R14
    mov     #0, R15
    mov     #10, R12
    call    #Calc_1000      ; R15 = R13 * 1000
    add     R15, R6
    jmp     End_Guardar_InputNumber

Pos_100:
    ; Calcular R13 * 100
    mov     R13, R14
    mov     #0, R15
    mov     #10, R12
    call    #Calc_100       ; R15 = R13 * 100
    add     R15, R6
    jmp     End_Guardar_InputNumber

Pos_10:
    ; Calcular R13 * 10
    mov     R13, R14
    mov     #0, R15
    mov     #10, R12
    call    #Calc_10        ; R15 = R13 * 10
    add     R15, R6
    jmp     End_Guardar_InputNumber

Pos_1:
    ; Sumar directamente el dígito (R13 * 1)
    add     R13, R6
    jmp     End_Guardar_InputNumber

; Subrutina auxiliar para calcular R14 * 10, resultado en R15
Calc_10:
    ; R15 += R14 * 10 = (R14 << 3) + (R14 << 1)
    mov     R14, R15
    rla     R15             ; R15 = R14 * 2
    rla     R15             ; R15 = R14 * 4
    rla     R15             ; R15 = R14 * 8
    add     R14, R15        ; R15 = (R14 * 8) + R14
    add     R14, R15        ; R15 = (R14 * 8) + (R14 * 2) = R14 * 10
    ret

; Subrutina auxiliar para calcular R14 * 100, resultado en R15
Calc_100:
    ; R15 = (R14 * 10) * 10
    call    #Calc_10        ; R15 = R14 * 10
    mov     R15, R14        ; Preparar para siguiente *10
    call    #Calc_10        ; R15 = (R14 * 10) * 10 = R14 * 100
    ret

; Subrutina auxiliar para calcular R14 * 1000, resultado en R15
Calc_1000:
    ; R15 = (R14 * 100) * 10
    call    #Calc_100       ; R15 = R14 * 100
    mov     R15, R14        ; Preparar para siguiente *10
    call    #Calc_10        ; R15 = (R14 * 100) * 10 = R14 * 1000
    ret

End_Guardar_InputNumber:
    ; Restaurar registros
    pop     R15
    pop     R14
    ret

;=====================================================================================================================
;
; Esta subrutina verifica el valor de R13 (index del digito 0-9) y le asigna a R10 el numero que vamos a display en el LCD
;
Get_7Segment_Code:
    
    cmp     #1, R13
    jeq     Code1
    cmp     #2, R13
    jeq     Code2
    cmp     #3, R13
    jeq     Code3
    cmp     #4, R13
    jeq     Code4
    cmp     #5, R13
    jeq     Code5
    cmp     #6, R13
    jeq     Code6
    cmp     #7, R13
    jeq     Code7
    cmp     #8, R13
    jeq     Code8
    cmp     #9, R13
    jeq     Code9

    mov.b   #0xFC, R10
    mov     #0, R13
    ret                         ; 


Code1:
    mov.b   #0x60, R10          ; 1 
    ret
Code2:
    mov.b   #0xDB, R10          ; 2 
    ret
Code3:
    mov.b   #0xF1, R10          ; 3 
    ret
Code4:
    mov.b   #0x67, R10          ; 4 
    ret
Code5:
    mov.b   #0xB7, R10          ; 5 
    ret
Code6:
    mov.b   #0xBF, R10          ; 6 
    ret
Code7:
    mov.b   #0xE0, R10          ; 7 
    ret
Code8:
    mov.b   #0xFF, R10          ; 8 
    ret
Code9:
    mov.b   #0xE7, R10          ; 9             
    ret
;
;
;------------------------------------------------------------------------------------------------------------------------------------
;
;
Blink_at_CurrentIndex:
    ; Verifica si todavía estamos en pantalla de input
    cmp.b   #3, R8
    jne     Volver_MainLoop     ; Si ya no estamos en input, salir del blink
    
    ; Verifica el índice actual
    cmp     #0, R9
    jeq     Blink0
    cmp     #1, R9
    jeq     Blink1
    cmp     #2, R9
    jeq     Blink2
    cmp     #3, R9
    jeq     Blink3
    cmp     #4, R9
    jeq     Blink4

    jmp     Blink_at_CurrentIndex          ; Sigue parpadeando

Volver_MainLoop:
    ret                         ; Volver al MAIN_LOOP

Blink0:
    mov.b   #0x00, &0x0A25      ; Apaga
    CALL    #Delay_500ms
    CALL    #Get_7Segment_Code
    mov.b   R10, &0x0A25        ; Vuelve a escribir el mismo número
    CALL    #Delay_500ms
    jmp Blink_at_CurrentIndex

Blink1:
    mov.b   #0x00, &0x0A23      ; Apaga
    CALL    #Delay_500ms
    CALL    #Get_7Segment_Code
    mov.b   R10, &0x0A23        ; Vuelve a escribir el mismo número
    CALL    #Delay_500ms
    jmp Blink_at_CurrentIndex

Blink2:
    mov.b   #0x00, &0x0A32      ; Apaga
    CALL    #Delay_500ms
    CALL    #Get_7Segment_Code
    mov.b   R10, &0x0A32        ; Vuelve a escribir el mismo número
    CALL    #Delay_500ms
    jmp Blink_at_CurrentIndex

Blink3:
    mov.b   #0x00, &0x0A2E      ; Apaga
    CALL    #Delay_500ms
    CALL    #Get_7Segment_Code
    mov.b   R10, &0x0A2E        ; Vuelve a escribir el mismo número
    CALL    #Delay_500ms
    jmp Blink_at_CurrentIndex

Blink4:
    mov.b   #0x00, &0x0A27      ; Apaga
    CALL    #Delay_500ms
    CALL    #Get_7Segment_Code
    mov.b   R10, &0x0A27        ; Vuelve a escribir el mismo número
    CALL    #Delay_500ms
    jmp Blink_at_CurrentIndex

;--------------------------------------------------------------------------------------------------------------------------


;
; Esta subrutina verifica en que index estamos del input number y hace display en ese indice del valor guardado en R10 con Get_7Segment_Code
;                               0 1 2 3 4        indexes
Display_at_index:            ;C 0 0 0 0 0        input number
    cmp     #0, R9
    jeq     Pos0
    cmp     #1, R9
    jeq     Pos1
    cmp     #2, R9
    jeq     Pos2
    cmp     #3, R9
    jeq     Pos3
    cmp     #4, R9
    jeq     Pos4

    ;mov 0 a r9
    ret

Pos0:                              
    mov.b   R10, &0x0A25    
    ret

Pos1:
    mov.b   R10, &0x0A23
    ret

Pos2:
    mov.b   R10, &0x0A32
    ret

Pos3:
    mov.b   R10, &0x0A2E
    ret

Pos4:
    mov.b   R10, &0x0A27        ; Último dígito (más a la derecha)
    ret


Incrementar_InputNumber_Index;
    inc   R9
    ret 

; hasta aqui funcionalidad input number
;======================================================================================================================================

Desplazamiento:
    CALL    #Actualiza_Display
    CALL    #Delay_500ms
    CALL    #Delay_500ms
    CALL    #Actualiza_Posicion
    RET

Actualiza_Posicion:
    INC.B   R6
    CMP.B   #44, R6 ;aqui
    JNE     no_reset
    MOV.B   #0, R6
no_reset:
    RET


Actualiza_Display:
            MOV.B   #pos1, R14         
            MOV.B   R6, R5             

; --- Dígito 1 ---
            MOV.B   stringNamesH(R5), 0x0A20(R14) 
            MOV.B   stringNamesL(R5), 0x0A20+1(R14)  

; --- Dígito 2 ---
            MOV.B   #pos2, R14          
            ADD.B   #1, R5
            CMP.B   #48, R5
            JL      CONT_1
            MOV.B   #0, R5
CONT_1:     MOV.B   stringNamesH(R5), 0x0A20(R14)  
            MOV.B   stringNamesL(R5), 0x0A20+1(R14)  

; --- Dígito 3 ---
            MOV.B   #pos3, R14          
            ADD.B   #1, R5
            CMP.B   #48, R5
            JL      CONT_2
            MOV.B   #0, R5
CONT_2:     MOV.B   stringNamesH(R5), 0x0A20(R14)  
            MOV.B   stringNamesL(R5), 0x0A20+1(R14)  

; --- Dígito 4 ---
            MOV.B   #pos4, R14          
            ADD.B   #1, R5
            CMP.B   #48, R5
            JL      CONT_3
            MOV.B   #0, R5
CONT_3:     MOV.B   stringNamesH(R5), 0x0A20(R14)  
            MOV.B   stringNamesL(R5), 0x0A20+1(R14)  

; --- Dígito 5 ---
            MOV.B   #pos5, R14          
            ADD.B   #1, R5
            CMP.B   #48, R5
            JL      CONT_4
            MOV.B   #0, R5
CONT_4:     MOV.B   stringNamesH(R5), 0x0A20(R14)  
            MOV.B   stringNamesL(R5), 0x0A20+1(R14)  

; --- Dígito 6 ---
            MOV.B   #pos6, R14
            ADD.B   #1, R5
            CMP.B   #48, R5
            JL      CONT_5
            MOV.B   #0, R5
CONT_5:     MOV.B   stringNamesH(R5), 0x0A20(R14)       
            MOV.B   stringNamesL(R5), 0x0A20+1(R14)  

            RET
;========================================================================================================================================================
;
;
Delay_50ms
            MOV.W   #5000, R15 
            CALL    #Loop_Delay_50ms
            RET            
      
Loop_Delay_50ms
            DEC.W   R15                 
            JNZ     Loop_Delay_50ms          
            RET 

Delay_500ms
            MOV.W   #50000, R15 
            CALL    #Loop_Delay_500ms
            RET            
      
Loop_Delay_500ms
            DEC.W   R15                 
            JNZ     Loop_Delay_500ms          
            RET  

Delay_20ms:
    MOV     #10000, R15       ; Ajusta este valor si tu reloj es más rápido/lento

Loop_Delay_20ms:
    DEC     R15
    JNZ     Loop_Delay_20ms
    RET

;
Salir_TimerA0_ISR:
    reti

StartTimer250ms:
    mov     #TASSEL_1 + MC_1 + ID_3, &TA0CTL ; ACLK, up, /8
    mov     #8192, &TA0CCR0
    mov     #CCIE, &TA0CCTL0
    ret

StopTimerA0:
    bic     #MC_1, &TA0CTL
    bic     #CCIE, &TA0CCTL0
    ret
;
;--------------------------------------------------------------------------------------------------------------------------------------------------------
; Subrutina de multiplicación: R14 = R14 * R15

Multiply:
    push    R12                   ; Guardar registros usados
    push    R13
    mov     #0, R12            ; Acumulador (resultado)
    mov     R15, R13          ; Copiar multiplicador
Multiply_Loop:
    tst     R13                     ; ¿Multiplicador es 0?
    jz      Multiply_End      ; Si sí, terminar
    bit     #1, R13               ; ¿Bit menos significativo es 1?
    jz      Skip_Add            ; Si no, saltar suma
    add     R14, R12           ; Sumar multiplicando al acumulador
Skip_Add:
    rla     R14                     ; Desplazar multiplicando a la izquierda (*2)
    rrc     R13                     ; Desplazar multiplicador a la derecha
    jmp     Multiply_Loop
Multiply_End:
    mov     R12, R14          ; Mover resultado a R14
    pop     R13
    pop     R12
    ret

; Subrutina de división: R14 = R14 / R15, R15 = residuo

Divide:
    push    R12                  ; Guardar registros usados
    push    R13
    mov     #0, R12           ; Cociente
    mov     R14, R13         ; Copiar dividendo
    tst     R15                    ; ¿Divisor es 0?
    jz      Divide_End       ; Si sí, salir
Divide_Loop:
    cmp     R15, R13          ; ¿Dividendo >= divisor?
    jlo        Divide_End        ; Si no, terminar
    sub      R15, R13          ; Restar divisor del dividendo
    inc       R12                    ; Incrementar cociente
    jmp     Divide_Loop
Divide_End:
    mov     R12, R14        ; Mover cociente a R14
    mov     R13, R15        ; Mover residuo a R15
    pop     R13
    pop     R12
    ret


;
;
;

Display_Timer_A0:


;--------------------------------------------------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

            .sect   ".int37"      ; Vector para interrupciones del Puerto 1
            .short  PORT1_ISR

            .sect   ".reset"
            .short  RESET

            .end
