; MSP430FR6989 - Encender LEDs mientras se mantiene presionado S1 o S2
; S1 (P1.1) controla LED rojo (P1.0)
; S2 (P1.2) controla LED verde (P9.7)
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

            .data
            .global boton1Presionado
            .global boton2Presionado
            .global modoOP
            .global modoActual
            .global modoSeleccionado

modoActual:         .byte 0
modoSeleccionado:   .byte 0            
boton1Presionado:   .byte 0        ; 0 = S1 no presionado, 1 = S1 presionado
boton2Presionado:   .byte 0        ; 0 = S1 no presionado, 1 = S1 presionado
modoOP:             .byte 0        ; Empieza en modo 0


            .text
RESET:
            mov.w   #__STACK_END, SP          ; Inicializa el stack
            mov.w   #WDTPW | WDTHOLD, &WDTCTL ; Detiene Watchdog

            ;--------------------------
            ; CONFIGURACIÓN DE LEDs
            CALL    #Init_LEDS


            ; Hacer init de los flags

            ;--------------------------
            ; CONFIGURACIÓN DE BOTONES S1 y S2
            CALL    #Init_Buttons
            CALL    #Init_LCD
            CALL    #Init_Display

            ; Configura interrupciones por flanco de BAJADA (botón presionado)
            CALL #Init_Interruptions

            bic.w   #LOCKLPM5, &PM5CTL0       ; Desbloquea GPIOs

            nop
            bis.w   #GIE, SR                  ; Habilita interrupciones globales
            nop

MAIN_LOOP:
    mov.b   &modoOP, R10
    cmp.b   #0, R10
    jne     Saltar_Desplazamiento

    mov.b   &boton1Presionado, R11
    cmp.b   #1, R11
    jne     Saltar_Desplazamiento
    CALL    #Desplazamiento
    CALL    #Delay_500ms


Saltar_Desplazamiento:
    jmp     MAIN_LOOP




;===========================================================================
;    Inits Individuales
;===========================================================================
Init_LEDS
    bis.b   #BIT0, &P1DIR             ; P1.0 como salida (LED rojo)
    bic.b   #BIT0, &P1OUT             ; Apagado al inicio

    bis.b   #BIT7, &P9DIR             ; P9.7 como salida (LED verde)
    bic.b   #BIT7, &P9OUT             ; Apagado al inic
    RET

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


;----------------------------------------------------------
; Interrupcion
;----------------------------------------------------------
;-------------------------------------------------------
; Subrutina: PORT1_ISR
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
PORT1_ISR:
    ; ========== S1 (P1.1) ==========
    bit.b   #BIT1, &P1IFG
    jz      check_S2
    bic.b   #BIT1, &P1IFG             ; Limpia bandera

    bit.b   #BIT1, &P1IN
    jnz     s1_subida                 ; Si P1.1 está en HIGH, es subida
    jmp     s1_bajada                 ; Si p1.1 esta low, es bajada

;-------------------------------------------------------
; Subrutina: s1_subida
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
s1_subida:  
    bic.b   #BIT0, &P1OUT             ; Apaga LED rojo
    mov.b   #0, &boton1Presionado     ; Bandera en 0
    bis.b   #BIT1, &P1IES             ; Próxima interrupción: bajada
    jmp     fin_ISR


;-------------------------------------------------------
; Subrutina: s1_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
s1_bajada:
    CALL    #Delay_20ms
    mov.b   &modoOP, R10
    
    cmp.b   #0, R10
    jeq     modo0_s1_bajada

    cmp.b   #1, R10
    jeq     modo1_s1_bajada

    cmp.b   #2, R10
    jeq     modo2_s1_bajada
    

    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: modo0_s1_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo0_s1_bajada:                        ; en modo 0 y modo 1 s1 hace lo mismo
    mov.b   #1, &boton1Presionado
    bis.b   #BIT0, &P1OUT
    bic.b   #BIT1, &P1IES
    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: modo1_s1_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo1_s1_bajada:
    mov.b   #0, &modoOP
    mov.b   #1, &boton1Presionado
    bis.b   #BIT0, &P1OUT
    bic.b   #BIT1, &P1IES
    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: modo2_s1_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo2_s1_bajada:
    bis.b   #BIT0, &P1OUT
    CALL    #Desplazar_Opcion_Modo
    CALL    #Display_Opcion_Modo
    jmp     fin_ISR


; ========== S2 (P1.2) ==========
;-------------------------------------------------------
; Subrutina: check_S2
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
check_S2:
    bit.b   #BIT2, &P1IFG
    jz      fin_ISR
    bic.b   #BIT2, &P1IFG

    bit.b   #BIT2, &P1IN
    jnz     s2_subida
    jmp     s2_bajada

;-------------------------------------------------------
; Subrutina: s2_subida
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
s2_subida:
    bic.b   #BIT7, &P9OUT             ; Apaga LED verde
    bis.b   #BIT2, &P1IES             ; Próxima interrupción: bajada
    mov.b   #0, &boton1Presionado      ; Bandera en 0
    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: s2_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
s2_bajada:
    CALL    #Delay_20ms
    mov.b   &modoOP, R10

    cmp.b   #0, R10
    jeq     modo0_s2_bajada

    cmp.b   #1, R10
    jeq     modo1_s2_bajada

    cmp.b   #2, R10
    jeq     modo2_s2_bajada

    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: modo0_s2_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo0_s2_bajada:
    bis.b   #BIT7, &P9OUT
    mov.b   #1, &modoOP
    mov.b   #1, &boton2Presionado
    CALL    #Display_Menu
    bic.b   #BIT2, &P1IES
    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: modo1_s2_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo1_s2_bajada:
    bis.b   #BIT7, &P9OUT
    MOV.B   #2, &modoOP
    CALL    #Display_Modo
    CALL    #Display_Opcion_Modo
    jmp     fin_ISR

;-------------------------------------------------------
; Subrutina: modo2_s2_bajada
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo2_s2_bajada:
    bis.b   #BIT7, &P9OUT
    MOV.B   #3, &modoOP
    CALL    #Guardar_Modo_Seleccionado

;-------------------------------------------------------
; Subrutina: fin_ISR
; Objetivo:  
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
fin_ISR:
    reti


;=======================================================
; Subrutinas
;=======================================================
    
;-------------------------------------------------------
; Subrutina: Display_Ready
; Objetivo: Refleja "READY", el icono del timer y los 
; corchetes de la bateria en el LCD
; Pre-condiciones:
; Post-condiciones:
; Autor: Angélica Cruz 
; Fecha:
;-------------------------------------------------------
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
;-------------------------------------------------------
; Subrutina: Display_Menu
; Objetivo: Refleja "MENU" en el LCD 
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
Display_Menu:
            ;Mov.B #1, &modoOP
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
;-------------------------------------------------------
; Subrutina: Display_Modo
; Objetivo: Refleja "MODO_X" en el LCD 
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
Display_Modo 
            MOV.B   #0x6C, &0xA29       ; "M" at A1
            MOV.B   #0xA0, &0xA2A

            MOV.B   #0xFC, &0xA25       ; "O" at A2
            MOV.B   #0x00, &0xA26 

            MOV.B   #0xF0, &0xA23       ; "D" at A3
            MOV.B   #0x50, &0xA24

            MOV.B   #0x9F, &0xA32       ; "E" at A4
            MOV.B   #0x00, &0xA33

            MOV.B   #0x10, &0xA2E       ; "_" at A5
            MOV.B   #0x00, &0xA2F

            MOV.B   #0x00, &0xA27       ; at A6
            MOV.B   #0x00, &0xA28

            RET   

;-------------------------------------------------------
; Subrutina: Display_Opcion_Modo
; Objetivo: Refleja las opciones de los modos en el LCD
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
Display_Opcion_Modo:
    MOV.B   &modoActual, R10

    CMP.B   #0, R10
    JEQ     modo_0
    CMP.B   #1, R10
    JEQ     modo_1
    CMP.B   #2, R10
    JEQ     modo_2
    CMP.B   #3, R10
    JEQ     modo_3
    CMP.B   #4, R10
    JEQ     modo_4
    RET

;-------------------------------------------------------
; Subrutina: modo_0
; Objetivo: Mascarilla del numero 0 display de modo
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo_0:
    MOV.B   #0xFC, &0xA27       ; 0 at A6
    MOV.B   #0x00, &0xA28
    RET
;-------------------------------------------------------
; Subrutina: modo_1
; Objetivo: Mascarilla del numero 1 display de modo
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo_1:
    MOV.B   #0x60, &0xA27       ; 1 at A6
    MOV.B   #0x20, &0xA28
    RET
;-------------------------------------------------------
; Subrutina: modo_2
; Objetivo: Mascarilla del numero 2 display de modo
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo_2:
    MOV.B   #0xDB, &0xA27       ; 2 at A6
    MOV.B   #0x00, &0xA28
    RET
;-------------------------------------------------------
; Subrutina: modo_3
; Objetivo: Mascarilla del numero 3 display de modo
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo_3:
    MOV.B   #0xF1, &0xA27       ; 3 at A6
    MOV.B   #0x00, &0xA28
    RET
;-------------------------------------------------------
; Subrutina: modo_4
; Objetivo: Mascarilla del numero 4 display de modo
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
modo_4:
    MOV.B   #0x67, &0xA27       ; 4 at A6
    MOV.B   #0x00, &0xA28
    RET

;-------------------------------------------------------
; Subrutina: Desplazar_Opcion_Modo 
; Objetivo: Desplazar las opciones de los modos que se
; reflejan en el LCD
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
Desplazar_Opcion_Modo:
    MOV.B   &modoActual, R10
    INC.B   R10
    CMP.B   #5, R10
    JNE     no_wrap
    MOV.B   #0, R10
;-------------------------------------------------------
; Subrutina: no_wrap 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
no_wrap:
    MOV.B   R10, &modoActual
    RET
;-------------------------------------------------------
; Subrutina: Guardar_Modo_Seleccionado 
; Objetivo: Desplazar las opciones de los modos que
; se reflejan en el LCD
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
Guardar_Modo_Seleccionado:
    MOV.B   &modoActual, R10
    MOV.B   R10, &modoSeleccionado
    RET

;-------------------------------------------------------
; Subrutina: Desplazamiento 
; Objetivo: Mueve el texto en el LCD hacia la izquierda
; Pre-condiciones:
; Post-condiciones:
; Autor: Angelica Cruz 
; Fecha:
;-------------------------------------------------------
Desplazamiento:
    CALL    #Actualiza_Display
    CALL    #Delay_500ms
    CALL    #Delay_500ms
    CALL    #Actualiza_Posicion
    RET
;-------------------------------------------------------
; Subrutina: Actualiza_Posicion 
; Objetivo: Aumenta el índice R6 para avanzar el desplazamiento
; Si llegamos al final del string, entonces reinicia el índice
; a 0 para que el desplazmiento sea cíclico
; Pre-condiciones:
; Post-condiciones:
; Autor: Angelica Cruz 
; Fecha:
;-------------------------------------------------------
Actualiza_Posicion:
    INC.B   R6
    CMP.B   #44, R6 ;aqui
    JNE     no_reset
    MOV.B   #0, R6
no_reset:
    RET

;-------------------------------------------------------
; Subrutina: Actualiza_Display 
; Objetivo: Actualiza el LCD con 6 caracters empezando en
; el índice indicado
; Pre-condiciones:
; Post-condiciones:
; Autor: Angelica Cruz 
; Fecha:
;-------------------------------------------------------
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

;-------------------------------------------------------
; Subrutina: Delay_500ms 
; Objetivo: Espera 500ms x 2 = 1s
; Pre-condiciones:
; Post-condiciones:
; Autor: Camila Hernandez 
; Fecha:
;-------------------------------------------------------
Delay_500ms
            MOV.W   #50000, R15 
;-------------------------------------------------------
; Subrutina: Loop_Delay_500ms 
; Objetivo: Espera 500ms x 2 = 1s
; Pre-condiciones:
; Post-condiciones:
; Autor: Camila Hernandez 
; Fecha:
;-------------------------------------------------------       
Loop_Delay_500ms
            DEC.W   R15                 
            JNZ     Loop_Delay_500ms          
            RET  
;-------------------------------------------------------
; Subrutina: Delay_20ms 
; Objetivo: Espera 20ms (ajustable)
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;-------------------------------------------------------
Delay_20ms:
    MOV     #5000, R15       ; Ajusta este valor si tu reloj es más rápido/lento
;-------------------------------------------------------
; Subrutina: Loop_Delay_20ms 
; Objetivo: Espera 500ms x 2 = 1s
; Pre-condiciones:
; Post-condiciones:
; Autor: Isander Paris 
; Fecha:
;------------------------------------------------------- 
Loop_Delay_20ms:
    DEC     R15
    JNZ     Loop_Delay_20ms
    RET

; === VARIABLES ===
; R8–R12 = valores individuales para los 5 dígitos
; R4 = índice del dígito actual (0–4)
; R5 = valor temporal del dígito actual
; R6 = posición en pantalla (0–5)
; R7 = bandera de parpadeo ON/OFF
; R13 = modo edición activo (1 = sí, 0 = no)

;-------------------------------------------------------
; Subrutina: SegmentTable
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SegmentTable:
    .byte   0x3F    ; 0
    .byte   0x06    ; 1
    .byte   0x5B    ; 2
    .byte   0x4F    ; 3
    .byte   0x66    ; 4
    .byte   0x6D    ; 5
    .byte   0x7D    ; 6
    .byte   0x07    ; 7
    .byte   0x7F    ; 8
    .byte   0x6F    ; 9
    .byte   0x39    ; 'C'

; === Dirección base de los dígitos en el display ===
LCD_BASE    .equ    0x0A20     ; Solo Prueba, podemos cambiarlo sino ajusta!!!!!!

; === FUNCIONES ===
;-------------------------------------------------------
; Subrutina: DigitToDisplay
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
; Entrada: R5 = valor (0–9 o código de letra), R6 = posición (0–5)
DigitToDisplay:
    ; Si el valor es un espacio (para ocultar), lo mostramos vacío
    cmp     #' ', R5
    jeq     MostrarEspacio

    ; Si es 'C' (67), usamos posición 10 de tabla
    cmp     #'C', R5
    jne     MostrarNumero
    mov     #10, R7
    jmp     CargarYMostrar
;-------------------------------------------------------
; Subrutina: MostrarNumero  
; Objetivo: Convertir número a índice (0–9)
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
MostrarNumero:
    mov     R5, R7
;-------------------------------------------------------
; Subrutina: CargarYMostrar 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
CargarYMostrar:
    ; Cargar valor de SegmentTable[R7]
    ; Dirección: SegmentTable + R7
    mov     #SegmentTable, R14
    add     R7, R14
    mov.b   @R14, R15           ; segmento en R15

    ; Calcular dirección del dígito (LCD_BASE + R6)
    mov     #LCD_BASE, R14
    add     R6, R14
    mov.b   R15, 0(R14)
    ret
;-------------------------------------------------------
; Subrutina: MostrarEspacio
; Objetivo: Mostrar 0x00 en esa posición
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
MostrarEspacio:
    mov     #LCD_BASE, R14
    add     R6, R14
    mov.b   #0x00, 0(R14)
    ret
;-------------------------------------------------------
; Subrutina: MostrarC00000 
; Objetivo: Mostrar todos los caracteres de C00000
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
MostrarC00000:
    mov     #'C', R5
    mov     #0, R6
    call    #DigitToDisplay

    mov     R8, R5
    mov     #1, R6
    call    #DigitToDisplay

    mov     R9, R5
    mov     #2, R6
    call    #DigitToDisplay

    mov     R10, R5
    mov     #3, R6
    call    #DigitToDisplay

    mov     R11, R5
    mov     #4, R6
    call    #DigitToDisplay

    mov     R12, R5
    mov     #5, R6
    call    #DigitToDisplay
    ret
;-------------------------------------------------------
; Subrutina: Init_Contador 
; Objetivo: Iniciar edición de contador
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
Init_Contador:
    mov     #0, R4
    mov     #0, R5
    mov     #1, R13
    call    #MostrarC00000
    call    #StartTimer250ms
    jmp     Esperar_Salir_Contador
;-------------------------------------------------------
; Subrutina: Esperar_Salir_Contador 
; Objetivo: Esperar fin de edición
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
Esperar_Salir_Contador:
    cmp     #1, R13
    jeq      Esperar_Salir_Contador
    ret
;-------------------------------------------------------
; Subrutina: TimerA0_ISR 
; Objetivo: ISR TIMER A0 (250ms)
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
TimerA0_ISR:
    cmp     #1, R13
    jne     Salir_TimerA0_ISR

    xor     #1, R7             ; alterna parpadeo
    mov     R4, R6
    cmp     #0, R7
    jeq      OcultarDigito

    call    #GetDigitoValor
    call    #DigitToDisplay
    jmp     Salir_TimerA0_ISR
;-------------------------------------------------------
; Subrutina: OcultarDigito 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
OcultarDigito:
    mov     #' ', R5
    call    #DigitToDisplay
;-------------------------------------------------------
; Subrutina: Salir_TimerA0_ISR 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
Salir_TimerA0_ISR:
    reti
;-------------------------------------------------------
; Subrutina: port1_ISR
; Objetivo: ISR de Botones
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
port1_ISR:
    bit     #BIT1, &P1IFG
    jz      S2_ISR_Handler
    bic     #BIT1, &P1IFG

    call    #GetDigitoValor
    inc     R5
    cmp     #10, R5
    jl      NoReset
    mov     #0, R5
;-------------------------------------------------------
; Subrutina: NoReset 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
NoReset:
    call    #SetDigitoValor
    ret
;-------------------------------------------------------
; Subrutina: S2_ISR_Handler 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
S2_ISR_Handler:
    bit     #BIT2, &P1IFG
    jz      Fin_ISR
    bic     #BIT2, &P1IFG

    call    #GetDigitoValor
    call    #SetDigitoValor

    inc     R4
    cmp     #5, R4
    jl      Fin_ISR

    mov     #0, R13
    call    #StopTimerA0
    call    #MostrarFREQ0
;-------------------------------------------------------
; Subrutina: Fin_ISR  
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
Fin_ISR:
    reti
;-------------------------------------------------------
; Subrutina: GetDigitoValor 
; Objetivo: Obtener valor del dígito actual
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
GetDigitoValor:
    cmp     #0, R4
    jeq      LoadR8
    cmp     #1, R4
    jeq      LoadR9
    cmp     #2, R4
    jeq      LoadR10
    cmp     #3, R4
    jeq      LoadR11
    cmp     #4, R4
    jeq      LoadR12
    ret
;-------------------------------------------------------
; Subrutina: LoadR8  
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
LoadR8:  mov R8, R5  ; temp en R5
    ret
;-------------------------------------------------------
; Subrutina: LoadR9 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
LoadR9:  mov R9, R5
    ret
;-------------------------------------------------------
; Subrutina: LoadR10 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
LoadR10: mov R10, R5
    ret
;-------------------------------------------------------
; Subrutina: LoadR11 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
LoadR11: mov R11, R5
    ret
;-------------------------------------------------------
; Subrutina: LoadR12 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
LoadR12: mov R12, R5
    ret
;-------------------------------------------------------
; Subrutina: SetDigitoValor 
; Objetivo: Guardar valor del dígito actual
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SetDigitoValor:
    cmp     #0, R4
    jeq      SaveR8
    cmp     #1, R4
    jeq      SaveR9
    cmp     #2, R4
    jeq      SaveR10
    cmp     #3, R4
    jeq      SaveR11
    cmp     #4, R4
    jeq      SaveR12
    ret
;-------------------------------------------------------
; Subrutina: SaveR8 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SaveR8:  mov R5, R8
    ret
;-------------------------------------------------------
; Subrutina: SaveR9 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SaveR9:  mov R5, R9
    ret
;-------------------------------------------------------
; Subrutina: SaveR10 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SaveR10: mov R5, R10
    ret
;-------------------------------------------------------
; Subrutina: SaveR11 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SaveR11: mov R5, R11
    ret
;-------------------------------------------------------
; Subrutina: SaveR12 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
SaveR12: mov R5, R12
    ret
;-------------------------------------------------------
; Subrutina: MostrarFREQ0 
; Objetivo: Mostrar texto al finalizar edición
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
MostrarFREQ0:
    ; Mostrar 'FREQ_0'

    ret
;-------------------------------------------------------
; Subrutina: StartTimer250ms 
; Objetivo: Timer 250ms usando ACLK
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
StartTimer250ms:
    mov     #TASSEL_1 + MC_1 + ID_3, &TA0CTL ; ACLK, up, /8
    mov     #8192, &TA0CCR0
    mov     #CCIE, &TA0CCTL0
    ret
;-------------------------------------------------------
; Subrutina: StopTimerA0 
; Objetivo: 
; Pre-condiciones:
; Post-condiciones:
; Autor: Edgardo Valle 
; Fecha: 20/abril/2025
;------------------------------------------------------- 
StopTimerA0:
    bic     #MC_1, &TA0CTL
    bic     #CCIE, &TA0CCTL0
    ret


;------------------------------------------------------------------------------=
            .global __STACK_END
            .sect   .stack

            .sect   ".int37"      ; Vector para interrupciones del Puerto 1
            .short  PORT1_ISR

            .sect   ".reset"
            .short  RESET

            .end
