;gsmhorn1.asm v1.1 for Siemens A35
;*** Assembler directives**************************************************************
            LIST      p=16F628a     ; Определение типа микроконтроллера.
#include   <p16F628A.inc>
            __CONFIG  03F21H       ; Биты конфигурации: защита выключена, WDT выкл,
                                   ; стандартный XT - генератор, PWRTE включен.
LENGTH      EQU 0x20     ; Length to send
NEW_SIGNAL  EQU 0x21     ; Bit0=1 if waiting for a new signal (to avoid sending the first 'random' LENGTH)
OBYTE       EQU 0x22     ; Original byte used in receive subroutine
BYTE        EQU 0x23     ; Byte used in send and receive subroutines
BITCOUNT    EQU 0x24     ; Bit counter used in send and receive subroutines
COUNT1      EQU 0x25     ; Time counter used in the delay subroutine
COUNT2      EQU 0x26     ; Time counter used in the delay subroutine
COUNT3      EQU 0x27     ; Time counter used in the delay subroutine
count0      EQU 0x28
;*** Beginning of the program ***********************************************************
            ORG 0x000    ; Processor reset vector
reset       GOTO init    ; Go to initialization
            ORG  0x009 
;*** Initializations ********************************************************************
init        bsf        STATUS,RP0  	; "Двойная" "штатная"  команда установки 
            bcf        STATUS,RP1  	; 1-го банка.
            clrf       VRCON^80H        ; Отключение источника опорного напряжения.

            MOVLW     b'11000101'        ; прерывание по переднему фронту
            MOVWF     OPTION_REG^80H     ; Configure options
            MOVLW     b'11111011'        ; RB0 (interrupt)  RB3 as output, others as inputs
            MOVWF     TRISB^80H          ; Configure PORTB
            MOVLW     b'00010011'        ; 
            MOVWF     TRISA^80H          ; Configure PORTA

            BCF       STATUS,RP0         ; Return to Bank 0
            movlw      .07         	 ; Отключение компараторов.
            movwf      CMCON       	 ; --------"--------
            clrf       T1CON       	 ; ----"----  TMR1.
            clrf       T2CON       	 ; ----"----  TMR2.
            clrf       CCP1CON     	 ; ----"----  CCP.
	    CLRF      PORTB              ; Initialize PORTB outputs to 0V
            CLRF      PORTA              ; Initialize PORTA outputs to 0V
            CLRF      INTCON           
            
            BSF       PORTA,2
            CALL      delay_1sec 
            BCF       PORTA,2 
            CALL      delay_1sec 
            BSF       PORTA,2
            CALL      delay_1sec
            BCF       PORTA,2  
           
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec

            BSF       INTCON,4           ;разрешение прерывания
            BSF       PORTA,2
            CALL      delay_1sec 
            BCF       PORTA,2 
            CALL      delay_1sec 
            BSF       PORTA,2
            CALL      delay_1sec
            BCF       PORTA,2 
           
            
thru        SLEEP 
            bcf      INTCON,1
thru1       SLEEP  
;По выходу из спячки зажигаем светодиод
            bsf       PORTA,2
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            call      delay_4sec
            bcf       PORTA,2

ALARM       BSF       PORTA,3 
;Подать команду "ATH0"
            MOVLW     d'6'               
            CALL      tx_w               
            MOVLW     d'5'               
            CALL      tx_w               
            MOVLW     d'3'               
            CALL      tx_w               
            MOVLW     d'65'              ; ASCII code for 'A'
            CALL      tx_w               ; Send W
            MOVLW     d'84'              ; ASCII code for 'T'
            CALL      tx_w               ; Send W
            MOVLW     d'72'              ; ASCII code for 'H'
            CALL      tx_w               ; Send W
            MOVLW     d'48'              ; ASCII code for '0'
            CALL      tx_w               ; Send W
            MOVLW     d'13'              ; ASCII code for Enter
            CALL      tx_w               ; Send W
            CALL      delay
;Команда "ATD>1;"
            MOVLW     d'6'                
            CALL      tx_w                
            MOVLW     d'7'                
            CALL      tx_w                
            MOVLW     d'1'                
            CALL      tx_w                
            MOVLW     d'65'              ; ASCII code for 'A'
            CALL      tx_w               ; Send W
            MOVLW     d'84'              ; ASCII code for 'T'
            CALL      tx_w               ; Send W
            MOVLW     d'68'              ; ASCII code for 'D'
            CALL      tx_w               ; Send W
            MOVLW     d'62'              ; ASCII code for '>'
            CALL      tx_w               ; Send W
            MOVLW     d'49'              ; ASCII code for '1'
            CALL      tx_w               ; Send W
            MOVLW     d'59'              ; ASCII code for ';'
            CALL      tx_w               ; Send W
            MOVLW     d'13'              ; ASCII code for Enter
            CALL      tx_w               ; Send W
;выдерживаем большую паузу
            CALL      big_delay
;Команда ATH0
            MOVLW     d'6'               
            CALL      tx_w                
            MOVLW     d'5'               
            CALL      tx_w                
            MOVLW     d'3'                
            CALL      tx_w                
            MOVLW     d'65'                
            CALL      tx_w 
            MOVLW     d'84' 
            CALL      tx_w 
            MOVLW     d'72' 
            CALL      tx_w 
            MOVLW     d'48' 
            CALL      tx_w 
            MOVLW     d'13' 
            CALL      tx_w 
            CALL      delay
;Команда "ATD>2;"
            MOVLW     d'6'                
            CALL      tx_w               
            MOVLW     d'7'               
            CALL      tx_w               
            MOVLW     d'1'               
            CALL      tx_w               
            MOVLW     d'65' 
            CALL      tx_w 
            MOVLW     d'84' 
            CALL      tx_w 
            MOVLW     d'68' 
            CALL      tx_w 
            MOVLW     d'62' 
            CALL      tx_w 
            MOVLW     d'50' 
            CALL      tx_w 
            MOVLW     d'59' 
            CALL      tx_w 
            MOVLW     d'13' 
            CALL      tx_w 
;выдерживаем большую паузу
            CALL      big_delay
            bcf       PORTA,3
            BCF       INTCON,1           ;сбросить бит прерывания
            btfsc     PORTB,0
            goto      ALARM
            GOTO      thru1
;*** Send subroutine *********************************************************
tx_w:       MOVWF     BYTE               ; Store byte to send (W) in BYTE
tx_start_bit: BCF      PORTB,2           ; logic 0 (start bit)
            NOP                          ; 1 Must wait 17 us for 57600 bauds
            NOP                          ; 2
            NOP                          ; 3
            NOP                          ; 4
            NOP                          ; 5
            NOP                          ; 6 Next bit will be set in 11 us from now
tx_data:    MOVLW     9                  ; Number of bits to send + 1
            MOVWF     BITCOUNT           ; Bit counter

tx_next_bit: DECFSZ    BITCOUNT,F        ; Decrement counter
            GOTO             tx_bit      ; If !=0, send the bit
            GOTO             tx_stop_bit ; Else send the stop bit

tx_bit:     RRF       BYTE,F             ; Rotate right to get next bit
            BTFSS     STATUS,C           ; If it's a zero
            GOTO      tx_0               ; Then send a 0
            GOTO      tx_1               ; Else send a 1

tx_0:       NOP                          ; To have the same delay than when it's a 1
            BCF       PORTB,2            ;  logic 0
            NOP                          ; 1 Must wait 17 us for 57600 bauds
            NOP                          ; 2
            NOP                          ; 3
            NOP                          ; 4
            NOP                          ; 5
            NOP                          ; 6 Next bit will be set in 11 us from now
            GOTO      tx_next_bit        ; Loop

tx_1:       BSF       PORTB,2            ; logic 1
            NOP                          ; 1 Must wait 17 us for 57600 bauds
            NOP                          ; 2
            NOP                          ; 3
            NOP                          ; 4
            NOP                          ; 5
            NOP                          ; 6 Next bit will be set in 11 us from now
            GOTO      tx_next_bit        ; Loop

tx_stop_bit: NOP                         ; 13 Requiered for the last data bit
            NOP                          ; 14
            NOP                          ; 15
            NOP                          ; 16
            BSF       PORTB,2            ;  logic 1 (stop bit)
            NOP                          ; 1 Must wait 17 us for 57600 bauds
            NOP                          ; 2
            NOP                          ; 3
            NOP                          ; 4
            NOP                          ; 5
            NOP                          ; 6
            NOP                          ; 7
            NOP                          ; 8
            NOP                          ; 9
            NOP                          ; 10
            NOP                          ; 11
            NOP                          ; 12
            NOP                          ; 13
            NOP                          ; 14
            NOP                          ; 15 The return will take the last 2 us
tx_done:    RETURN                       ; All bits send, return

;*** Delay subroutine ***********************************************************
delay:      MOVLW     d'200'             ; Delay duration
            MOVWF     COUNT1             ; Initialize COUNT1
            MOVLW     d'255'             ; Maximum value
            MOVWF     COUNT2             ; Initialize COUNT2
            DECFSZ    COUNT2,F           ; COUNT2--
            GOTO      $-1                ; Loop until COUNT2=0
            DECFSZ    COUNT1,F           ; COUNT1--
            GOTO      $-5                ; Loop until COUNT1=0
            RETURN 
;*** Big delay subroutine *********************************************************
big_delay:  MOVLW     d'120'     
            MOVWF     COUNT3             ; Initialize COUNT1
mm:         BSF       PORTB,3 
            CALL      delay
            BCF       PORTB,3 
            DECFSZ    COUNT3,F           ; COUNT3--
            GOTO      mm                 ; Loop until COUNT3=0
            RETURN 


;*** Подпрограмма задержки в 1 секунду *** 
delay_1sec   
             movlw            .66  
             movwf            count0
sec          clrf             TMR0
ms           btfss	      INTCON,T0IF
             goto    	      ms 
	     bcf	      INTCON,T0IF
             decfsz           count0,f
             goto             sec          
             return  
;*** Подпрограмма задержки в 4 секунды*** 
delay_4sec:   
             movlw            .255  
             movwf            count0
sec1         clrf             TMR0
ms1          btfss	      INTCON,T0IF
             goto    	      ms1 
	     bcf	      INTCON,T0IF
             decfsz           count0,f
             goto             sec1          
             return
             end     
;*** End of program *************************************************************


