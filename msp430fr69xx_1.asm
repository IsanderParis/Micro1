; MSP430FR6989 - Encender LEDs mientras se mantiene presionado S1 o S2
; S1 (P1.1) controla LED rojo (P1.0)
; S2 (P1.2) controla LED verde (P9.7)

            .cdecls C,LIST,"msp430.h"


            .text
            .def    RESET
;----------------------------------------

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
modoOP:             .byte 0      ; Empieza en modo 0


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
    jne     skip_scroll

    mov.b   &boton1Presionado, R11
    cmp.b   #1, R11
    jne     skip_scroll
    CALL    #Scroll
    CALL    #DELAY


skip_scroll:
    jmp     MAIN_LOOP




;===============
;    Inits Individuales
;============
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
    CALL    #UPDATE_DISPLAY
    RET


;----------------------------------------
; Interrupcion
;---------
PORT1_ISR:
    ; ========== S1 (P1.1) ==========
    bit.b   #BIT1, &P1IFG
    jz      check_S2
    bic.b   #BIT1, &P1IFG             ; Limpia bandera

    bit.b   #BIT1, &P1IN
    jnz     s1_subida                 ; Si P1.1 está en HIGH, es subida
    jmp     s1_bajada                   ; si p1.1 esta low, es bajada

s1_subida:  
    bic.b   #BIT0, &P1OUT             ; Apaga LED rojo
    mov.b   #0, &boton1Presionado      ; Bandera en 0
    bis.b   #BIT1, &P1IES             ; Próxima interrupción: bajada
    jmp     fin_ISR



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

modo0_s1_bajada:                        ; en modo 0 y modo 1 s1 hace lo mismo
    mov.b   #1, &boton1Presionado
    bis.b   #BIT0, &P1OUT
    bic.b   #BIT1, &P1IES
    jmp     fin_ISR

modo1_s1_bajada:
    mov.b   #0, &modoOP
    mov.b   #1, &boton1Presionado
    bis.b   #BIT0, &P1OUT
    bic.b   #BIT1, &P1IES
    jmp     fin_ISR

modo2_s1_bajada:
    bis.b   #BIT0, &P1OUT
    CALL    #Scroll_Mode_Options
    CALL    #Display_Mode__Option
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
    mov.b   #0, &boton1Presionado      ; Bandera en 0
    jmp     fin_ISR

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

modo0_s2_bajada:
    bis.b   #BIT7, &P9OUT
    Mov.B #1, &modoOP
    mov.b   #1, &boton2Presionado
    CALL    #Display_Menu
    bic.b   #BIT2, &P1IES
    jmp     fin_ISR

modo1_s2_bajada:
    bis.b   #BIT7, &P9OUT
    MOV.B   #2, &modoOP
    CALL #Display_Mode
    CALL #Display_Mode__Option
    jmp     fin_ISR

modo2_s2_bajada:
    bis.b   #BIT7, &P9OUT
    MOV.B   #3, &modoOP
    CALL    #Save_Selected_Mode


fin_ISR:
    reti


;========================
; subrutinas
;================
    
;-------------------------------------------------------
; Subroutine: READY_SCREEN
; Purpose: Displays "READY" anf timer icon on the LCD
;(still need to implement the timer)
;-------------------------------------------------------
READY_SCREEN:
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

            RET

; Display Menu
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

;display Mode
Display_Mode 
            MOV.B   #0x6C, &0xA29               ; "M" at A1
            MOV.B   #0xA0, &0xA2A

            MOV.B   #0xFC, &0xA25               ; "o" at A2
            MOV.B   #0x00, &0xA26 

            MOV.B   #0xF0, &0xA23               ; D at A3
            MOV.B   #0x50, &0xA24

            MOV.B   #0x9F, &0xA32               ; E at A4
            MOV.B   #0x00, &0xA33

            MOV.B   #0x10, &0xA2E               ; _ at A5
            MOV.B   #0x00, &0xA2F

            MOV.B   #0x00, &0xA27               ; at A6
            MOV.B   #0x00, &0xA28

            RET   

;Display_Mode__Option
Display_Mode__Option:
    MOV.B   &modoActual, R10

    CMP.B   #0, R10
    JEQ     mode_0
    CMP.B   #1, R10
    JEQ     mode_1
    CMP.B   #2, R10
    JEQ     mode_2
    CMP.B   #3, R10
    JEQ     mode_3
    CMP.B   #4, R10
    JEQ     mode_4
    RET

mode_0:
    MOV.B   #0xFC, &0xA27       ; 0 at A6
    MOV.B   #0x00, &0xA28
    RET

mode_1:
    MOV.B   #0x60, &0xA27       ; 1 at A6
    MOV.B   #0x20, &0xA28
    RET

mode_2:
    MOV.B   #0xDB, &0xA27       ; 2 at A6
    MOV.B   #0x00, &0xA28
    RET

mode_3:
    MOV.B   #0xF1, &0xA27       ; 3 at A6
    MOV.B   #0x00, &0xA28
    RET

mode_4:
    MOV.B   #0x67, &0xA27       ; 4 at A6
    MOV.B   #0x00, &0xA28
    RET


Scroll_Mode_Options:
    MOV.B   &modoActual, R10
    INC.B   R10
    CMP.B   #5, R10
    JNE     no_wrap
    MOV.B   #0, R10
no_wrap:
    MOV.B   R10, &modoActual
    RET


; Save_Selected_Mode
Save_Selected_Mode:
    MOV.B   &modoActual, R10
    MOV.B   R10, &modoSeleccionado
    RET


;-------------------------------------------------------------------------------------
; Subroutine: Scroll
; Purpose: Se encarga de mover el texto en la pantalla hacia la izquierda
;------------------------------------------------------------------------------------
Scroll:
    CALL    #UPDATE_DISPLAY
    CALL    #DELAY
    CALL    #DELAY
    CALL    #Update_Position
    RET

;-------------------------------------------------------
; Subroutine: Update_Position
; Purpose: Aumenta el índice R6 para avanzar el scroll. Si ya llegamos al final del string
;   entonces reinicia el índice a 0 para que el scroll sea cíclico.
;-------------------------------------------------------
Update_Position:
    INC.B   R6
    CMP.B   #44, R6 ;aqui
    JNE     no_reset
    MOV.B   #0, R6
no_reset:
    RET


;-------------------------------------------------------------------------------
; Subroutine: UPDATE_DISPLAY
; Purpose: Update the LCD with 6 characters starting at the given index
; Input: R6 = scroll position (0 to 2)
;-------------------------------------------------------------------------------
UPDATE_DISPLAY:
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


;-------------------------------------------------------------------------------
; Subroutine: DELAY
; Purpose: Waits 500ms x 2 = 1s
;-------------------------------------------------------------------------------
DELAY
            MOV.W   #50000, R15        
DELAY_LOOP
            DEC.W   R15                 
            JNZ     DELAY_LOOP          
            RET  

; Delay_20ms: ~20ms delay (ajustable)
Delay_20ms:
    MOV     #5000, R15       ; Ajusta este valor si tu reloj es más rápido/lento
delay_loop:
    DEC     R15
    JNZ     delay_loop
    RET


;----------------------------------------
            .global __STACK_END
            .sect   .stack

            .sect   ".int37"      ; Vector para interrupciones del Puerto 1
            .short  PORT1_ISR

            .sect   ".reset"
            .short  RESET

            .end
