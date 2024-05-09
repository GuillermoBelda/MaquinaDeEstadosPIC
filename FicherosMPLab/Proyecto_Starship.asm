;Control Starship
;Guillermo José Belda García UPCT 2024


list p=16F876A
#include <p16f876a.inc>

__CONFIG _WDT_OFF & _XT_OSC & _LVP_OFF

;ASM OUTPUTS REGISTERS
	OUT0		EQU		0x30
	OUT1		EQU		0x31	
;ASM STATE REGISTERS
	STATE		EQU		0x40  	; STATE Register
	NEXTSTATE	EQU		0x41  	; NEXTSTATE Register
;ASM STATES (Literal)
	St0_CD			EQU		.0		
	St1_FD			EQU		.13		
	St2_EI			EQU		.2		
	St3_MQ			EQU		.3
	St4_SS			EQU		.4
	St5_OF			EQU		.5
	St6_RE			EQU		.6
	St7_EI			EQU		.7
	St8_ES			EQU		.8
	St9_SL			EQU		.9
	St10_FTS		EQU		.10
	ResultadoADC	EQU		.43
;Contadores de tiempo(Estados)
    Contador_Tiempo	EQU	    .42
	;; 4s = 80 ciclos
	;; 8s = 160 ciclos
	;;10s = 200 ciclos
	;;12s = 240 ciclos
org 0
			goto	inicio
    
; Definición de vectores de interrupción
org 4
    		goto InterTMR0

; Inicialización del programa
org 5
inicio		

; Configuración Puertos y habilitación de interrupciones
; Configuración de Timer1
;El TMR1 trabaja con oscilador interno Fosc/4 y un preescaler de 1:256. Si se trabaja a una frecuencia
;de 4 MHz, el TMR0 deberá cargarse con 6250 para que provocar interrupción a los 0.05s
;(195 * 256 * 1 =50000uS=0.05s")
			BCF STATUS, RP0 ;
			BCF STATUS, RP1 ; Banco 0
			CLRF PORTA ; Iniciamos el  PORTA 
			CLRF PORTB ; Iniciamos el PORTB
			CLRF PORTC ; Iniciamos el PORTC
			MOVLW b'00001001'
			MOVWF ADCON0
	    	BSF STATUS, RP0 ; Me muevo al banco 1
			
			MOVLW b'00000100' ; bits de configuración del convertidor A/D
			MOVWF ADCON1 ; 
			MOVLW b'00110010' 	; 
			MOVWF TRISA 	; 

;;			MOVLW 0x06 ; 
;;			MOVWF ADCON1 ; 
			MOVLW b'00000000' 	; 
			MOVWF TRISB 



			MOVLW b'00000000' 	
			MOVWF TRISC 	


			bcf	STATUS,RP0
			BSF STATUS, RP0 ; Me muevo al banco 1
			movlw	0x07	;Habilita TMR0
			movwf	OPTION_REG

			bcf		STATUS,RP0
			movlw	.60		;; 256-196
			movwf	TMR0

			BSF STATUS, RP0 ; Me muevo al banco 1
			movlw	0xE0		;;Pasar a hexa
   			movwf	INTCON
			
			BCF STATUS, RP0 ;
			BCF STATUS, RP1 ; Banco 0

; Inicializamos el nuevo estado 									
			movlw	.0				
			movwf	NEXTSTATE		;=St0
			
loop   		goto loop

; ######################################################################################    
; Rutina de interrupción del Timer0
InterTMR0	
			;;incf	Contador_Tiempo
			incf 	Contador_Tiempo, W
			movwf	Contador_Tiempo
			movlw	0x3C
			movwf	TMR0				
			bcf		INTCON,TMR0IF	;Borramos el flag del TMR0	
			call mostrar_numero





;#################################
;### MAQUINA DE ESTADOS ###
;#################################
;### ACTUALIZAMOS LA TABLA
			movf	NEXTSTATE,W
			movwf	STATE			; Update STATE=NEXTSTATE
	
;### STATE JUMP TABLE ###
			addlw	.0				
			rlf		STATE,W			
			addwf	PCL,F
			call	State0			
			goto 	break
			call	State1			
			goto 	break
			call	State2		
			goto 	break
			call    State3
        	goto    break
        	call    State4
       		goto    break
       		call    State5
        	goto    break
        	call    State6
        	goto    break
        	call    State7
        	goto    break
        	call    State8
        	goto    break
        	call    State9
        	goto    break
        	call    State10
        	goto    break
break		retfie

;###########################ESTADOS######################################
;### State0
State0		
			movlw	b'00000000'
			movwf	OUT0		; 
			movwf 	PORTC		
ST0_N1		btfss	PORTA,5		;Comprobamos si la entrada 5 está activa
			goto	ST0_N1_NO
			goto	ST0_N1_YES
ST0_N1_YES	movlw	.1 ;St1_FD		; NEXTSTATE = St1
			movwf	NEXTSTATE
			goto 	ST0_SALIDA
ST0_N1_NO	movlw	St0_CD
			movwf	NEXTSTATE
ST0_SALIDA	CLRF	Contador_Tiempo
			return



State1		movlw	b'00011000'
			movwf	OUT0
			movwf	PORTC
			movlw	.80
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	St1_N1_NO
			goto	St1_N1_YES
St1_N1_NO	movlw	.1 ;St1_FD
			movwf	NEXTSTATE
			goto	ST1_SALIDA
St1_N1_YES	movlw 	St2_EI
			movwf	NEXTSTATE
			CLRF Contador_Tiempo
ST1_SALIDA	
			return


State2		movlw	b'00101100'
			movwf	OUT0
			movwf	PORTC
			movlw	.160
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	COND_TIEMPO2_NO
			goto 	COND_TIEMPO2_OK
COND_TIEMPO2_OK movlw .10 ;St10_FTS
			movwf	NEXTSTATE
			goto	ST2_SALIDA	;Salgo
COND_TIEMPO2_NO bsf ADCON0, GO				;#######ComprobaciónADC
			WAIT_FOR_ADC2:
				btfsc   ADCON0, GO   ; Verificar si la conversión está en curso
        		goto    WAIT_FOR_ADC2

			movf	ADRESH, W
			movwf	ResultadoADC
;			movwf	PORTB
			movf	b'11110000', W
			andwf	ResultadoADC, W
			movwf	ResultadoADC
			movlw	b'10110000'
			subwf	ResultadoADC, W
			btfss	STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	ST2_2_SALIDA	
			movlw	.3 ;St3_MQ
			movwf	NEXTSTATE
ST2_SALIDA	CLRF Contador_Tiempo
ST2_2_SALIDA 
			return




State3		movlw	b'00110100'
			movwf	OUT0
			movwf	PORTC
			movlw	.200
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	COND_TIEMPO3_NO
			goto 	COND_TIEMPO3_OK
COND_TIEMPO3_OK movlw .10 ;St10_FTS
			movwf	NEXTSTATE
			goto	ST3_SALIDA	;Salgo
COND_TIEMPO3_NO bsf ADCON0, GO				;#######ComprobaciónADC
			WAIT_FOR_ADC3:
				btfsc   ADCON0, GO   ; Verificar si la conversión está en curso
        		goto    WAIT_FOR_ADC3
			
			movfw	ADRESH
			movwf	ResultadoADC
;			movwf	PORTB
			movlw	b'11110000'
			andwf	ResultadoADC, W
			movwf	ResultadoADC
			movlw	b'10110000'
			subwf	ResultadoADC, W
			btfss	STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	ST3_2_SALIDA	
			movlw	.4; St4_SS
			movwf	NEXTSTATE

ST3_SALIDA	CLRF Contador_Tiempo
ST3_2_SALIDA
			return










State4		movlw	b'01000010'
			movwf	OUT0
			movwf	PORTC
			movlw	.160
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z	;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	COND_TIEMPO4_NO
			goto 	COND_TIEMPO4_OK
COND_TIEMPO4_OK movlw .10 ;St10_FTS
			movwf	NEXTSTATE
			goto	ST4_SALIDA	;Salgo
COND_TIEMPO4_NO bsf ADCON0, GO				;#######ComprobaciónADC
			WAIT_FOR_ADC4:
				btfsc   ADCON0, GO   ; Verificar si la conversión está en curso
        		goto    WAIT_FOR_ADC4

			movfw	ADRESH
			movwf	ResultadoADC
;			movwf	PORTB
			movlw	b'11110000'
			andwf	ResultadoADC, W
			movwf	ResultadoADC
			movlw	b'10110000'
			subwf	ResultadoADC, W
			btfss	STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	ST4_2_SALIDA	
			movlw	.5; St5_OF
			movwf	NEXTSTATE

ST4_SALIDA	CLRF Contador_Tiempo
ST4_2_SALIDA
			return




State5		movlw	b'01010000'
			movwf	OUT0
			movwf	PORTC
			btfss	PORTA,4
			goto	ST5_N1_NO
			goto	ST5_N1_YES
ST5_N1_NO	movlw	St5_OF
			movwf	NEXTSTATE
			goto	S5_N1_SALIDA
ST5_N1_YES	movlw	.6; St6_RE
			movwf	NEXTSTATE		
S5_N1_SALIDA CLRF Contador_Tiempo
 			return




State6		movlw	b'01100010'
			movwf	OUT0
			movwf	PORTC
			movlw	.240
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	COND_TIEMPO6_NO
			goto 	COND_TIEMPO6_OK
COND_TIEMPO6_OK movlw .10 ;St10_FTS
			movwf	NEXTSTATE
			goto	ST6_SALIDA	;Salgo
COND_TIEMPO6_NO bsf ADCON0, GO				;#######ComprobaciónADC
			WAIT_FOR_ADC6:
				btfsc   ADCON0, GO   ; Verificar si la conversión está en curso
        		goto    WAIT_FOR_ADC6

			movfw	ADRESH
			movwf	ResultadoADC
;			movwf	PORTB
			movlw	b'11110000'
			andwf	ResultadoADC, W
			movwf	ResultadoADC
			movlw	b'10110000'
			subwf	ResultadoADC, W
			btfss	STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	ST6_2_SALIDA	
			movlw	.7; St7_EI
			movwf	NEXTSTATE
ST6_SALIDA	CLRF Contador_Tiempo
ST6_2_SALIDA
			return

State7		movlw	b'01110011'
			movwf	OUT0
			movwf	PORTC
			movlw	.160
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	COND_TIEMPO7_NO
			goto 	COND_TIEMPO7_OK
COND_TIEMPO7_OK movlw .10 ;St10_FTS
			movwf	NEXTSTATE
			goto	ST7_SALIDA	;Salgo
COND_TIEMPO7_NO bsf ADCON0, GO				;#######ComprobaciónADC
			WAIT_FOR_ADC7:
				btfsc   ADCON0, GO   ; Verificar si la conversión está en curso
        		goto    WAIT_FOR_ADC7
			
			movfw	ADRESH
			movwf	ResultadoADC
;			movwf	PORTB
			movlw	b'11110000'
			andwf	ResultadoADC, W
			movwf	ResultadoADC
			movlw	b'10110000'
			subwf	ResultadoADC, W
			btfss	STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	ST7_2_SALIDA	
			movlw	.8; St8_ES
			movwf	NEXTSTATE
			
ST7_SALIDA	CLRF Contador_Tiempo
ST7_2_SALIDA
			return

State8		movlw	b'10000000'
			movwf	OUT0
			movwf	PORTC
			movlw	b'00000000'
			movwf	PORTB
			movlw	.80
			subwf	Contador_Tiempo ,W
			btfss   STATUS, Z		;Salta la siguiente linea si el acarreo es 0 (mayor o igual)
			goto	ST8_N1_NO
			goto	ST8_N1_YES
ST8_N1_NO	movlw	St8_ES
			movwf	NEXTSTATE
			goto	ST_SALIDA	
ST8_N1_YES	movlw	.9; St9_SL
			movwf	NEXTSTATE
			CLRF Contador_Tiempo
ST_SALIDA	
		    return

State9		movlw	b'10010000'
			movwf	OUT0
			movwf	PORTC
			movlw	b'00000000'
			movwf	PORTB
			movlw	.9; St9_SL
			movwf	NEXTSTATE
		    return

State10		movlw   b'11110000'
			movwf	OUT0
			movwf	PORTC
			movlw	b'00000000'
			movwf	PORTB
			movlw	.10; St10_FTS
			movwf	NEXTSTATE
			return


mostrar_numero:
	movlw b'00000000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_1
	movlw b'00111111' ; 0
    movwf PORTB ; Mostrar segmento A
    return

probar_1
	movlw b'00010000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_2
    movlw b'00000110' ; 1
    movwf PORTB ; Mostrar segmentos B y C
	return

probar_2
	movlw b'00100000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_3
    movlw b'01011011' ; 2
    movwf PORTB ; Mostrar segmentos A, B, G, E y D
	return

probar_3
	movlw b'00110000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_4
    movlw b'01001111' ; 3
    movwf PORTB ; Mostrar segmentos A, B, C, D y G
	return

probar_4
	movlw b'01000000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_5
    movlw b'01100110' ; 4
    movwf PORTB ; Mostrar segmentos F, B, C y G
	return

probar_5
	movlw b'01010000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_6
    movlw b'01101101' ; 5
    movwf PORTB ; Mostrar segmentos A, F, C, D y G
	return

probar_6
	movlw b'01100000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_7
    movlw b'01111101' ; 6
    movwf PORTB ; Mostrar segmentos A, F, C, D, G y E
	return

probar_7
	movlw b'01110000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_8
    movlw b'00000111' ; 7
    movwf PORTB ; Mostrar segmentos A, B y C
	return

probar_8
	movlw b'10000000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
    goto probar_9
    movlw b'01111111' ; 8
    movwf PORTB ; Mostrar todos los segmentos
	return
probar_9
	movlw b'10010000'
    subwf ResultadoADC, W
    btfss STATUS, Z ;Salto la siguiente linea si el número coincide
	return
    movlw b'01101111' ; 9
    movwf PORTB ; Mostrar segmentos A, B, C, F y G
    return ; Retornar de la rutina
;###
;#################################
;#################################
;#################################
end
