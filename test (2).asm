#include <p18f452.inc>

TIME	set 0x02
loop_cnt1 set 0x03
loop_cnt2 set 0x04
loop_cnt3 set 0x05

			org 0x00
			goto main
			org 0x08
			goto intRoutin
			org 0x18
			retfie

main		CALL portSet
			CALL second
			CALL setTime

check		CALL inPower
			CALL incTime
			BRA check

;Port setup subroutine
;==============================================================================================
portSet		MOVLW B'11110000'
			MOVWF TRISA,A		; Setting up PORTA
			SETF TRISB,A		; Setting up PORTB
			CLRF TRISC,A		; Setting up PORTC
			CLRF TRISD,A		; Setting up PORTD
			CLRF TRISE,A		; Setting up PORTE

			CLRF PORTA,A		; Setting up PORTA
			CLRF PORTB,A		; Setting up PORTB
			CLRF PORTC,A		; Setting up PORTC
			CLRF PORTD,A		; Setting up PORTD
			CLRF PORTE,A		; Setting up PORTE
			CLRF TIME,A
			return


;Predefined settings subroutine
;==============================================================================================
inPred		BTFSS PORTA,4,A		; Defrost Meat
			BRA dePoultry
			BSF	PORTA,0,A
			MOVLW D'48'
			MOVWF loop_cnt3,A
again1 		CALL preTime
			DECFSZ loop_cnt3,F,A
			BRA again1
			

dePoultry	BTFSS PORTA,5,A		; Defrost Poultry
			BRA deSeafood
			BSF	PORTA,1,A
			MOVLW D'36'
			MOVWF loop_cnt3,A
again2 		CALL preTime
			DECFSZ loop_cnt3,F,A
			BRA again2


deSeafood	BTFSS PORTA,6,A	 	; Defrost Seafood
			BRA check1
			BSF	PORTA,2,A
			MOVLW D'24'
			MOVWF loop_cnt3,A
again3 		CALL preTime
			DECFSZ loop_cnt3,F,A
			BRA again3


check1		CALL inStart
			return


;Power settings subroutine
;==============================================================================================
inPower		BTFSS PORTB,4,A		; Defrost
			BRA lowPower
			BSF	PORTA,0,A

lowPower	BTFSS PORTB,5,A		; Low Power
			BRA midPower
			BSF	PORTA,1,A

midPower	BTFSS PORTB,6,A		; Medium Power
			BRA highPower
			BSF	PORTA,2,A
			
highPower	BTFSS PORTB,7,A		; High Power
			BRA checkP
			BSF	PORTA,3,A		
checkP		return


;Time settings subroutine
;==============================================================================================
incTime		BTFSS PORTB,0,A		; Increase Time
			BRA decTime		
preTime		TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			TBLRD*+
			MOVLW 0x99			; Determine last number on dataset
			CPFSEQ TABLAT,A
			CAll timeInc10
			

decTime		BTFSS PORTB,1,A		; Decrease Time
			BRA checkT
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			TBLRD*-
			MOVLW 0x88				; Determine last number on dataset
			CPFSEQ TABLAT,A
			CALL timeDec10

checkT		return


;Start subroutine
;==============================================================================================
inStart		BTFSS PORTB,2,A
			BTFSS PORTB,3,A		; Start Microwave
			BRA skip
			CALL tableOn

skip		return


;TurnTable subroutine
;==============================================================================================
tableOn		BSF	PORTE,2,A		; Bi-colour LED Red
			BSF	PORTE,1,A		; TurnTable On
			return

tableOff	BCF	PORTE,2,A		; Bi-colour LED Green
			BCF	PORTE,1,A		; TurnTable Off
			CALL buzzOn
			return


;Buzzer subroutine
;==============================================================================================
buzzOn		BSF	PORTE,0,A		; Buzzer On
			CALL delay1s
			BCF	PORTE,0,A		; Buzzer Off
			CALL delay1s
			BSF	PORTE,0,A		; Buzzer On
			CALL delay1s
			BCF	PORTE,0,A		; Buzzer Off
			return


;Interrupt setup subroutine
;==============================================================================================
intSet		BSF RCON,IPEN,A		; Configure Int2
			BSF INTCON,GIEH,A
			BSF INTCON,GIEL,A
			BCF INTCON3,INT2IF,A
			BSF INTCON3,INT2IP,A
			BSF INTCON3,INT2IE,A
			BSF INTCON2,INTEDG2,A
			return

intRoutin	BCF INTCON3,INT2IF,A
			CALL tableOff
			retfie


;Seven-segment Display
;==============================================================================================
second		MOVLW LOW secData	; Read MyData from program memory
			MOVWF TBLPTRL,A
			MOVLW HIGH secData
			MOVWF TBLPTRH,A
			MOVLW UPPER secData
			MOVWF TBLPTRU,A
			TBLRD*+
			TBLRD*+


secCoun		TBLRD*+
			CALL delay1s
			MOVLW 0x88				; Determine last number on dataset
			CPFSEQ TABLAT,A
			CALL timeCoun
			CPFSEQ TABLAT,A
			BRA secCoun
			CALL tableOff
			return


timeCoun	MOVLW D'60'
			INCF TIME,F,A
			CPFSEQ TIME,A
			MOVFF TABLAT,PORTC		; Move data to PORTC
			CPFSEQ TIME,A
			BRA time
			CALL minute
time		return


timeInc10	MOVLW D'6'
			INCF TIME,F,A
			CPFSEQ TIME,A
			MOVFF TABLAT,PORTC		; Move data to PORTC
			CPFSEQ TIME,A
			BRA timeI10
			CALL minute
timeI10		return


timeDec10	MOVLW D'6'
			INCF TIME,F,A
			CPFSEQ TIME,A
			MOVFF TABLAT,PORTC		; Move data to PORTC
			CPFSEQ TIME,A
			BRA timeD10
			CALL minute
timeD10		return


minute		CLRF PORTC,A
			MOVFF TABLAT,PORTD		; Move data to PORTD
			CLRF TIME,A
			return


secData 	DB 0x88,0x00,0x01,0x02,0x03,0x04,0x05,0x06
      		DB 0x07,0x08,0x09,0x10,0x11,0x12,0x13,0x14
      		DB 0x15,0x16,0x17,0x18,0x19,0x20,0x21,0x22
      		DB 0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x30
      		DB 0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38
      		DB 0x39,0x40,0x41,0x42,0x43,0x44,0x45,0x46
      		DB 0x47,0x48,0x49,0x50,0x51,0x52,0x53,0x54
      		DB 0x55,0x56,0x57,0x58,0x59,0x01
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x02
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x03
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x04
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x05
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x06
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x07
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x08
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x09
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x10
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x11
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x12
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x13
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x14
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x15
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x16
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x02
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x17
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x18
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x19
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x20
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x21
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x22
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x23
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x24
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x25
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x26
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x27
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x28
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x29
			DB 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08
      		DB 0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16
      		DB 0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24
      		DB 0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32
      		DB 0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40
      		DB 0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48
      		DB 0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56
      		DB 0x57,0x58,0x59,0x30,0x99


;Delay subroutine for 2MHz
;==============================================================================================
setTime		BSF	RCON,IPEN, A
			BSF	INTCON,GIEH, A
			BSF	INTCON,GIEL, A
			BCF	PIR1,TMR1IF, A
			BSF	IPR1,TMR1IP, A
			BSF	PIE1,TMR1IE, A
			return

delay1s		MOVLW 0XFD
			MOVWF T1CON,A
			MOVLW 0X0B
			MOVWF TMR1H,A
			MOVLW 0XDC
			MOVWF TMR1L,A
			BCF PIR1,TMR1IF,A
			BSF	T1CON,TMR1ON,A
wait		BTFSS PIR1,TMR1IF,A
			BRA	wait
			BCF	T1CON,TMR1ON,A
			return


			END