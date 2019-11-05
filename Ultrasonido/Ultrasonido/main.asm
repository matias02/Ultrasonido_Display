;
; Ultrasonido.asm
;
; Created: 2019-11-04 7:23:06 PM
; Author : Matias
;

; Replace with your application code
.ORG   0x0000
   	RJMP   START
.ORG   INT0addr
   	RJMP   INT_ECHO
.ORG   OC2Aaddr
  	RJMP   T2_COMPA
.ORG   OC1Aaddr
  	RJMP   T1_COMPA

;.......................................	
;Definicion de registros
;.......................................
.DEF   TMP = r20
.DEF   ESTADO = r21
.DEF   FLAG = r22
.DEF   OVT = r23
.DEF   DISTANCIA = r24
START:
   	; Inicializar variables globales
   	LDI      	FLAG, 0x00
	LDI      	OVT, 0x00
	LDI      	DISTANCIA, 0x00
 
   	; Configuración de la Pila
   	LDI      	r16, LOW(RAMEND)
   	OUT      	SPL, r16
   	LDI      	r16, HIGH(RAMEND)
   	OUT      	SPH, r16
 
   	; Configuración de interrupciones externas
   	LDI      	r16, 0x01
   	STS      	EICRA, r16 ; Activa int. en cualquier cambio de nivel lógico
   	LDI      	r16, 0x01
   	OUT      	EIMSK, r16 ; habilita INT0


;.......................................	
;Configuración del Timer 1
;.......................................
   	LDI      	r16, 0x00 ; Normal Mode, WGM11:WGM10 = 00
   	STS      	TCCR1A, r16
   	LDI      	r16, 0b00001101  ; Prescaler 8 - WGM13:WGM12 = 00
   	STS      	TCCR1B, r16
   	LDI      	r16, 0x02 ; Activa interrupcion por OCA
   	STS      	TIMSK1, r16
	LDI      	r16, 0x03
   	STS      	OCR1AH, r16 ; Apaga pin PB0 en 10us
	LDI      	r16, 0xD1
   	STS      	OCR1AL, r16 ; Apaga pin PB0 en 10us

;.......................................	
;Configuración del Timer 2
;.......................................
   	LDI      	r16, 0b00000010 ; CTC Mode
   	STS      	TCCR2A, r16
	LDI      	r16, 0x01	;Prescaler 1
   	STS      	TCCR2B, r16
	LDI      	r16, 0x02	; Activa interrupcion por OCRA2
   	STS      	TIMSK2, r16
   	LDI      	r16, 0x0A
   	STS      	OCR2A, r16   ; Apaga pin PB0 en 10us

;.......................................	
;Configuración de Puertos
;.......................................
	RCALL		UART_CONFIG
	LDI			ESTADO, 0x01
	;Puerto D
	LDI      	r16, 0x80 ; Define puertos B y D
   	OUT      	DDRD, r16
	;Puerto B
   	LDI      	r17, 0x02
   	OUT      	DDRB, r17
	//clr			TMP
	//out			PORTB, TMP
;.......................................	
;Habilito interrupciones globales
;.......................................
	SEI
;.......................................	
;MAIN
;.......................................
	MAIN:
	
	//RCALL		DELAY
	RJMP		MAIN

	

T1_COMPA:
	; eleva el trigger
	SBI PORTB, 1
	
	;Timer 2 en 10us
   	LDI      	r16, 0x01	;Prescaler 1
   	STS      	TCCR2B, r16
	LDI      	r16, 0x0F
   	STS      	OCR2A, r16   ; Apaga pin PB0 en 10us
	LDI      	r16, 0x02	; Activa interrupcion por OCRA2
   	STS      	TIMSK2, r16
	; Reiniciar cuenta
   	CLR      	r16
   	STS      	TCNT1H, r16
   	STS      	TCNT1L, r16
	; Seteo estado en 1
	LDi			ESTADO, 0x01 
	

	RETI
   	

T2_COMPA:
	;SBI PORTD, 7

	CPI estado, 0x02
	BRNE Baja
	SBI PORTD, 7
	inc ovt
	;RCALL		UART_TRANSMIT
	RETI
Baja:
	CBI PORTB, 1
	;Desactiva timer2
	LDS			r16, TCCR2B
	ANDI		r16, 0b11111000
   	STS      	TCCR2B, r16
	LDI      	r16, 0x00	; Desctiva interrupcion por OCRA2
   	STS      	TIMSK2, r16
	reti
	

	
INT_ECHO:
	; Guarda Registros
   	PUSH		r16
   	IN       	r16, SREG
   	PUSH		r16
 
   	CPI      	FLAG, 0x00
   	BRNE     	FLANCO_BAJADA ;Salta a flanco de bajada cuando el echo regresa
	SER      	FLAG
	;Limpio OVT
   	CLR			OVT
	
	;Modifico el timer 2 para cada centimetro
	LDI      	r16, 0x01	;Prescaler 1
   	STS      	TCCR2B, r16
	LDI      	r16, 0x3A
   	STS      	OCR2A, r16   ; Apaga pin PB0 en 10us
	LDI      	r16, 0x02	; Activa interrupcion por OCRA2
   	STS      	TIMSK2, r16
	LDi			estado, 0x02; Seteo estado en 0

	; Reiniciar cuenta
   	CLR      	r16
   	STS      	TCNT1H, r16
   	STS      	TCNT1L, r16
	RETI
 
FLANCO_BAJADA:
   	CLR      	FLAG
	; Guardar Distancia
	//MOV			DISTANCIA, OVT
	dec			ovt
	RCALL		UART_TRANSMIT
	
	; Desactiva Timer 2
	LDS			r16, TCCR2B
	ANDI		r16, 0b11111000
   	STS      	TCCR2B, r16
   	LDI      	r16, 0x00	; Desctiva interrupcion por OCRA2
	STS      	TIMSK2, r16

 SALIDA:
   	; Recupera Registros
   	POP	   		r16
   	OUT      	SREG, r16
   	POP      	r16
   	RETI
 
  
UART_CONFIG:
; Configuracion del UART con un BaudRate de 9600 a 1MHz, se activa la interrupcion para el recepcion del uart. 
; Baud rate = 9600 @ 1MHz
	ldi r16, 12; 
	ldi r17, 0;
	sts UBRR0H, r17
	sts UBRR0L, r16
; Enable transmitter and receiver with interrupt
	ldi r16, (1<<RXEN0)|(1<<TXEN0)|(1<<RXCIE0)
	sts UCSR0B, r16
; 8 data bits, 1 stop bit
	ldi r16, (1<<UCSZ00)|(1<<UCSZ01)
	sts UCSR0C, r16
; se habilita la opcion de x2 la velocidad para mejorar el error del baud rate
	ldi r18, (1<<U2X0)
	sts UCSR0A, r18
	ret

UART_TRANSMIT:
	; Esta subrutina se encarga de enviar un dato guardado en el registro r17 por Tx de UART
	; data in r17
	lds r16, UCSR0A
	sbrs r16, UDRE0
	rjmp UART_TRANSMIT
	sts UDR0, OVT
	ret
	
DELAY:
    ldi  r18, 6
    ldi  r19, 19
    ldi  r25, 174
L1: dec  r25
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    rjmp PC+1
