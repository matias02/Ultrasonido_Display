;
; Ultrasonido.asm
;
; Created: 2019-11-04 7:23:06 PM
; Author : Matias
;

; Replace with your application code
.ORG   0x0000
   	RJMP   START
//.ORG   INT0addr
  // 	RJMP   INT_ECHO
.ORG   OC2Aaddr
  	RJMP   T2_COMPA
.ORG   OC1Aaddr
  	RJMP   T1_COMPA


.DEF   temp = r23
.DEF   estado = r20
.DEF   FLAG = r28
.DEF   ovt = r21

START:


	
	;Configuración del Timer1
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

; Configuración TIMER 2
   	LDI      	r16, 0b00000010 ; CTC Mode
   	STS      	TCCR2A, r16
	LDI      	r16, 0x01	;Prescaler 1
   	STS      	TCCR2B, r16
	LDI      	r16, 0x02	; Activa interrupcion por OCRA2
   	STS      	TIMSK2, r16
   	LDI      	r16, 0x0A
   	STS      	OCR2A, r16   ; Apaga pin PB0 en 10us

;COnf puertos
	LDI estado, 0x01
	;Puerto D
	LDI      	r16, 0x00 ; Define puertos B y D
   	OUT      	DDRD, r16
	;Puerto B
   	LDI      	r17, 0x02
   	OUT      	DDRB, r17
	clr			temp
	out			portb, temp
   	LDI      	temp, 0x00
   	OUT      	DDRC, temp
	SEI
	main:
	rjmp		main

T1_COMPA:
	; eleva el trigger
	SBI PORTB, 1
	;Timer 2 en 10us
   	LDI      	r16, 0x01	;Prescaler 1
   	STS      	TCCR2B, r16
	LDI      	r16, 0x0F
   	STS      	OCR2A, r16   ; Apaga pin PB0 en 10us

   	

T2_COMPA:
	CPI estado, 0x00
	BRNE Baja
	inc ovt
	RETI
Baja:
	CBI PORTB, 1
	;Desactiva timer2
	LDI      	r16, 0x00	;Prescaler 0
   	STS      	TCCR2B, r16
	reti
/*
INT_ECHO:
	; Guarda Registros
   	PUSH		r16
   	IN       	r16, SREG
   	PUSH		r16
 
   	CPI      	FLAG, 0x00
   	BRNE     	flanco_bajada ;Salta a flanco de bajada cuando el echo regresa
   	SER      	FLAG
   	; Guardar cuenta
   	LDS      	r24, TCNT1L
   	LDS      	r25, TCNT1H
   	; Reiniciar cuenta
   	CLR      	r16
   	STS      	TCNT1H, r16
   	STS      	TCNT1L, r16
   	STS      	TIMSK1, r16 ; Desactiva interrupcion por OCA
   	RJMP     	salir1
 
flanco_bajada:
   	CLR      	FLAG
   	; Guardar nueva cuenta
   	LDS      	ECHOL, TCNT1L	;guarda la cuenta en registro ECHOL y ECHOH
   	LDS      	ECHOH, TCNT1H
   	LDI      	r16, 0x02	; Desactiva interrupcion por OCA
   	STS      	TIMSK1, r16
	CPI			ECHOL, 0x0F ; Salta a alarma cuando distancia menor a 15
	BRLO     	ALARMA
 
salir1:
   	; Recupera Registros
   	POP	   		r16
   	OUT      	SREG, r16
   	POP      	r16
   	RETI
 
ALARMA:
	MOV			temp, ECHOL
	swap		temp

   	andi		temp, 0x01
	//OUT      	PORTD, temp 	; Indica alarma
   	RJMP     	salir1

	*/