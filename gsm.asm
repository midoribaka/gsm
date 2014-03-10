;gsmhorn1.asm v1.1 for Siemens A35
;*** Assembler directives**************************************************************
<<<<<<< HEAD
            LIST      p=16F628a     ; Ô–“≈ƒ≈Ã≈Œ…≈ ‘…–¡ Õ…À“œÀœŒ‘“œÃÃ≈“¡.
#include   <p16F628A.inc>
            __CONFIG  03F21H       ; ‚…‘Ÿ ÀœŒ∆…«’“¡√……: ⁄¡›…‘¡ ◊ŸÀÃ¿ﬁ≈Œ¡, WDT ◊ŸÀÃ,
                                   ; ”‘¡Œƒ¡“‘ŒŸ  XT - «≈Œ≈“¡‘œ“, PWRTE ◊ÀÃ¿ﬁ≈Œ.
=======
            LIST      p=16F628a     ; –û–ø—Ä–µ–¥–µ–ª–µ–Ω–∏–µ —Ç–∏–ø–∞ –º–∏–∫—Ä–æ–∫–æ–Ω—Ç—Ä–æ–ª–ª–µ—Ä–∞.
#include   <p16F628A.inc>
            __CONFIG  03F21H       ; –ë–∏—Ç—ã –∫–æ–Ω—Ñ–∏–≥—É—Ä–∞—Ü–∏–∏: –∑–∞—â–∏—Ç–∞ –≤—ã–∫–ª—é—á–µ–Ω–∞, WDT –≤—ã–∫–ª,
                                   ; —Å—Ç–∞–Ω–¥–∞—Ä—Ç–Ω—ã–π XT - –≥–µ–Ω–µ—Ä–∞—Ç–æ—Ä, PWRTE –≤–∫–ª—é—á–µ–Ω.
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
init        bsf        STATUS,RP0  	; "‰◊œ Œ¡—" "€‘¡‘Œ¡—"  ÀœÕ¡Œƒ¡ ’”‘¡Œœ◊À… 
            bcf        STATUS,RP1  	; 1-«œ ¬¡ŒÀ¡.
            clrf       VRCON^80H        ; Ô‘ÀÃ¿ﬁ≈Œ…≈ …”‘œﬁŒ…À¡ œ–œ“Œœ«œ Œ¡–“—÷≈Œ…—.

            MOVLW     b'11000101'        ; –“≈“Ÿ◊¡Œ…≈ –œ –≈“≈ƒŒ≈Õ’ ∆“œŒ‘’
=======
init        bsf        STATUS,RP0  	; "–î–≤–æ–π–Ω–∞—è" "—à—Ç–∞—Ç–Ω–∞—è"  –∫–æ–º–∞–Ω–¥–∞ —É—Å—Ç–∞–Ω–æ–≤–∫–∏ 
            bcf        STATUS,RP1  	; 1-–≥–æ –±–∞–Ω–∫–∞.
            clrf       VRCON^80H        ; –û—Ç–∫–ª—é—á–µ–Ω–∏–µ –∏—Å—Ç–æ—á–Ω–∏–∫–∞ –æ–ø–æ—Ä–Ω–æ–≥–æ –Ω–∞–ø—Ä—è–∂–µ–Ω–∏—è.

            MOVLW     b'11000101'        ; –ø—Ä–µ—Ä—ã–≤–∞–Ω–∏–µ –ø–æ –ø–µ—Ä–µ–¥–Ω–µ–º—É —Ñ—Ä–æ–Ω—Ç—É
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
            MOVWF     OPTION_REG^80H     ; Configure options
            MOVLW     b'11111011'        ; RB0 (interrupt)  RB3 as output, others as inputs
            MOVWF     TRISB^80H          ; Configure PORTB
            MOVLW     b'00010011'        ; 
            MOVWF     TRISA^80H          ; Configure PORTA

            BCF       STATUS,RP0         ; Return to Bank 0
<<<<<<< HEAD
            movlw      .07         	 ; Ô‘ÀÃ¿ﬁ≈Œ…≈ ÀœÕ–¡“¡‘œ“œ◊.
=======
            movlw      .07         	 ; –û—Ç–∫–ª—é—á–µ–Ω–∏–µ –∫–æ–º–ø–∞—Ä–∞—Ç–æ—Ä–æ–≤.
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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

<<<<<<< HEAD
            BSF       INTCON,4           ;“¡⁄“≈€≈Œ…≈ –“≈“Ÿ◊¡Œ…—
=======
            BSF       INTCON,4           ;—Ä–∞–∑—Ä–µ—à–µ–Ω–∏–µ –ø—Ä–µ—Ä—ã–≤–∞–Ω–∏—è
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;œ ◊Ÿ»œƒ’ …⁄ ”–—ﬁÀ… ⁄¡÷…«¡≈Õ ”◊≈‘œƒ…œƒ
=======
;–ü–æ –≤—ã—Ö–æ–¥—É –∏–∑ —Å–ø—è—á–∫–∏ –∑–∞–∂–∏–≥–∞–µ–º —Å–≤–µ—Ç–æ–¥–∏–æ–¥
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;œƒ¡‘ÿ ÀœÕ¡Œƒ’ "ATH0"
=======
;–ü–æ–¥–∞—Ç—å –∫–æ–º–∞–Ω–¥—É "ATH0"
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;ÎœÕ¡Œƒ¡ "ATD>1;"
=======
;–ö–æ–º–∞–Ω–¥–∞ "ATD>1;"
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;◊Ÿƒ≈“÷…◊¡≈Õ ¬œÃÿ€’¿ –¡’⁄’
            CALL      big_delay
;ÎœÕ¡Œƒ¡ ATH0
=======
;–≤—ã–¥–µ—Ä–∂–∏–≤–∞–µ–º –±–æ–ª—å—à—É—é –ø–∞—É–∑—É
            CALL      big_delay
;–ö–æ–º–∞–Ω–¥–∞ ATH0
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;ÎœÕ¡Œƒ¡ "ATD>2;"
=======
;–ö–æ–º–∞–Ω–¥–∞ "ATD>2;"
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;◊Ÿƒ≈“÷…◊¡≈Õ ¬œÃÿ€’¿ –¡’⁄’
            CALL      big_delay
            bcf       PORTA,3
            BCF       INTCON,1           ;”¬“œ”…‘ÿ ¬…‘ –“≈“Ÿ◊¡Œ…—
=======
;–≤—ã–¥–µ—Ä–∂–∏–≤–∞–µ–º –±–æ–ª—å—à—É—é –ø–∞—É–∑—É
            CALL      big_delay
            bcf       PORTA,3
            BCF       INTCON,1           ;—Å–±—Ä–æ—Å–∏—Ç—å –±–∏—Ç –ø—Ä–µ—Ä—ã–≤–∞–Ω–∏—è
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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


<<<<<<< HEAD
;*** œƒ–“œ«“¡ÕÕ¡ ⁄¡ƒ≈“÷À… ◊ 1 ”≈À’Œƒ’ *** 
=======
;*** –ü–æ–¥–ø—Ä–æ–≥—Ä–∞–º–º–∞ –∑–∞–¥–µ—Ä–∂–∫–∏ –≤ 1 —Å–µ–∫—É–Ω–¥—É *** 
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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
<<<<<<< HEAD
;*** œƒ–“œ«“¡ÕÕ¡ ⁄¡ƒ≈“÷À… ◊ 4 ”≈À’ŒƒŸ*** 
=======
;*** –ü–æ–¥–ø—Ä–æ–≥—Ä–∞–º–º–∞ –∑–∞–¥–µ—Ä–∂–∫–∏ –≤ 4 —Å–µ–∫—É–Ω–¥—ã*** 
>>>>>>> b4bc1820ac4aa24cab519b52015166ad99a41bb7
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


