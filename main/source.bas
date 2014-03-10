'**********************************
'TheBug, SIO4-00
'GSM Supervision and control system
'Sends alarms as SMS text through a GSM modem
'Receives SMS commands for switching on a relay
'Ready for flash for PCB: SIO4-00
'version no. 0.b
'(c) 2008 - owdk (at) yahoo.com
'**********************************

'configure the appropriate port and pin directions
TRISA = %11110110
TRISB = %01011111  'RS232 output must be conf. as 'input' to tri-state I/O driver

'Declare variables
Dim i As Word
Dim j As Byte
Dim k As Byte
Dim x As Byte
Dim y As Byte
Dim n As Byte
Dim a As Byte

Dim temp As Byte
Dim data(64) As Byte  'buffer for serial data
Dim serdata As Byte

Dim startmark As Bit
Dim quote As Bit
Dim pincode As Bit
Dim smsreceived As Bit
Dim modemready As Bit

Dim check_sms_count As Byte  'Number of sec. before next check of SMS
Dim alarmcount As Byte  'Number of sec. before turning off the output
Dim delaycount As Byte  'No. of delays per sec.

Dim hour As Byte  'variables for the internal clock - clock not used
Dim min As Byte
Dim sec As Byte

Dim hw_enable_status As Bit
Dim armed As Bit  'input enabled = 1

Dim z1trigged As Bit  'set if zone is trigged
Dim z2trigged As Bit  'set if zone is trigged
Dim z3trigged As Bit  'set if zone is trigged
Dim z4trigged As Bit  'set if zone is trigged

Dim pwr_status As Bit
Dim powerfailure As Bit


'Definition of I/O ports
'remember to set TRISA and TRISB according to I/O definition

Symbol hw_enable = PORTA.2  'high= inputs enabled
Symbol zone1 = PORTB.4  'input: zone 1, low=active
Symbol zone2 = PORTB.3  'input: zone 2, low=active
Symbol zone3 = PORTB.0  'input: zone 3, low=active
Symbol zone4 = PORTA.4  'input: zone 4, low=active
Symbol aux_out = PORTA.0  'Siren port
Symbol relay = PORTA.3  'output relay
Symbol led = PORTB.5  'status LED
Symbol pwr_sense = PORTA.1  'input for power monitoring



'**** MAIN PROGRAM ****
main:
'disable comperator in RA0-3
	ASM:        MOVLW 0x07
	ASM:        MOVWF CMCON
relay = 0
aux_out = 0

WaitMs 2000  'wait for system to stabilize (charge pumps in rs232 drivers)

'initialize serial hw port - port used for modem
Hseropen 9600

'more uart specific initialization
ASM:        bcf status,rp0
ASM:        bsf rcsta,spen
ASM:        bcf rcsta,rx9
ASM:        bcf rcsta,sren
ASM:        bsf rcsta,cren
ASM:        bcf rcsta,ferr
ASM:        bcf rcsta,rx9d
'clear peripheral flags
ASM:        clrf pir1
'clear uart receiver
ASM:        movf RCREG,W
ASM:        movf RCREG,W
ASM:        movf RCREG,W
'initiating txif flag by sending anything
ASM:        movlw 0
ASM:        movwf txreg

'disable interrupts
ASM:        clrf pie1


Define SEROUT_DELAYUS = 5000
'SW serial port TX PORTB.6
'SW serial port RX PORTB.7

'**** Initialize modem *********
start:
'Send AT command to modem and check respons. Repeat until respons received
led = 1
Gosub modem_ready
If modemready = True Then
	'initialise modem
	Hserout "ate0", CrLf  'disable echo from modem.
	Gosub waiting
	Hserout "at+cpms=", 0x22, "SM", 0x22, CrLf  'use memory on SIM card
	Gosub waiting
	Hserout "at+cnmi=0,0,0,0", CrLf  'default value. Modem sends no respons for new message
	WaitMs 500
	Hserout "AT+CMGF=1"  'setup text mode for SMS format
	Gosub waiting
	Hserout "at+cmgd=1"  'delete message in first position if any.
	Gosub waiting
Else
	Goto start
Endif

'read primary phone number
Gosub waiting
read_first_phoneno:
Hserout "at+cpbf=", 0x22, "PRI", 0x22, CrLf
Gosub get_number
If j > 0 Then
	Write 0, j
	j = j - 1  'number of digits
	For k = 0 To j Step 1
		temp = data(k)
		n = k + 1
		Write n, temp  'store number in eeprom
	Next k
Else
	WaitMs 1000
	Goto read_first_phoneno
Endif




'********** Main loop ******************
hw_enable_status = 0
armed = 0
delaycount = 0
alarmcount = 0
check_sms_count = 0

hour = 0
min = 0
sec = 0

led = 0
menu:
	WaitMs 250  'stroke signal
	Gosub decrement_counters
	Gosub check_arming
	Gosub check_zones
	Gosub update_siren
	Gosub check_power
	Gosub check_sms
Goto menu
End                                               


'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
decrement_counters:
'all timed events are based on counters.
If delaycount = 0 Then
	'all counters/timers are in seconds
	If check_sms_count > 0 Then
		check_sms_count = check_sms_count - 1
	Endif
	If alarmcount > 0 Then
		alarmcount = alarmcount - 1
	Endif
	'count the hours from power on...
	If min = 60 Then
		hour = hour + 1
		min = 0
	Else
		If sec = 60 Then
			min = min + 1
			sec = 0
		Else
			sec = sec + 1
		Endif
	Endif
	delaycount = 4  'one count is 250 mS
Else
	delaycount = delaycount - 1
Endif
Return                                            

check_arming:
'********************************
'hw = 1 (åben) -> hw_status = 0/armed = 0, armed 0 -> 1, hw_status 0->1
'hw = 0 -> rutine afvikles ikke, armed = 0, siren shut-off

If hw_enable <> hw_enable_status Then
	'HW enable input changed.
	armed = hw_enable
	hw_enable_status = hw_enable
Endif
If armed = 1 Then
	led = 0
Else
	led = 1
	alarmcount = 0
Endif
Return                                            



check_zones:
'***********************************************
'check zones in every scan
If armed = 1 Then
		If zone1 = 1 Then
			If z1trigged = False Then
			'zone activated
				z1trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Indgang 1 aktiv!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z1trigged = False
		Endif
		If zone2 = 0 Then
			If z2trigged = False Then
			'zone activated
				z2trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Indgang 2 aktiv!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z2trigged = False
		Endif
		If zone3 = 0 Then
			If z3trigged = False Then
			'zone activated
				z3trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Indgang 3 aktiv!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z3trigged = False
		Endif
		If zone4 = 1 Then
			If z4trigged = False Then
			'zone activated
				z4trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Indgang 4 aktiv!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z4trigged = False
		Endif
Endif
Return                                            

check_power:
'************************************************
If pwr_sense <> pwr_status Then
	'send SMS if changed
	Gosub init_sms
	If pwr_sense = False Then
	'power lost
		Hserout "Forsyning tabt"
	Else
	'power restored
		powerfailure = True
		Hserout "Forsyning OK"
	Endif
	Hserout 0x1a  'Ascii 26
	pwr_status = pwr_sense
Endif
Return                                            


update_siren:
'******************************
'sound alarm if armed (alarmcount will only be set if armed)
If armed = 1 Then
	If alarmcount > 0 Then
		aux_out = 1
	Else
		aux_out = 0
	Endif
Else
	alarmcount = 0
	aux_out = 0
Endif
Return                                            

check_sms:
'***********************************
'check for new SMS message every 10 sec.
If check_sms_count = 0 Then
		Toggle led
		Gosub check_for_message  'check if a message is received
		If smsreceived = True Then
			Hserout "AT", CrLf
			Gosub waiting
			Hserout "at+cmgd=1", CrLf  'delete message
			Gosub waiting
			Hserout "at+cmgd=1", CrLf  'delete message
			Gosub waiting
		Endif
		Gosub check_command
		Toggle led
		check_sms_count = 8  'Set number of counts for next check
	Endif
Return                                            


init_sms:
'*******************************
'send initial string to modem
	Toggle led
	Hserout "AT", CrLf
	Gosub waiting
	'send SMS
	Hserout "at+cmgs=", 0x22
	Read 0, temp  'read no. of digits in phone no.
	'+4530123456
	For j = 1 To temp
		Read j, x
		Hserout x
	Next j
	Hserout 0x22, CrLf
	Gosub waiting
	Toggle led
Return                                            

check_for_message:
'****************
'check for message in pos. 1
'respons:
'if no massage available in this position:
'+CMS ERROR: 321
'if message available in this position, e.g.:
'+CMGR: "REC UNREAD","+45xxxxxxxx",,"dd/mm/yy,hh:mm:ss+08"
'#1268:0'
'read data and store in buffer if '#' found. j contains no. of characters stored
j = 0
i = 0
startmark = False
smsreceived = False
Hserout "AT", CrLf
Gosub waiting
Hserout "at+cmgr=1", CrLf
loop:
	Gosub hserget2
	If serdata > 0 Then
		'check if quote is found->this is not an error message
		If serdata = 0x22 Then
			smsreceived = True
		Endif
		If serdata = "#" And smsreceived = True Then
			startmark = True
		Endif
		If startmark = True Then
			data(j) = serdata  'store data in buffer
			If j = 64 Then  'handle buffer overflow
				j = 0
			Else
				j = j + 1
			Endif
		Endif
	Endif
	i = i + 1
	If i = 10000 Then Return  'timeout
Goto loop
Return                                            

check_command:
'****************************
If j > 0 Then  'buffer contains data
	j = j - 1
	'check pincode in command
	'pin code is 4 digit after #-sign in SMS stored in data().
	'this is compared with the last 4 digits of primary phone number stored
	'in eeprom (1st position is the length of the stored phone number
	pincode = True
	Read 0, x  'read number of digits in phone number
	y = x - 4  'cal. start position for pin-code compare
	For j = 1 To 4 Step 1
		y = y + 1  'calculate relative offset for phone no.
		Read y, a  'read digit in
		x = data(j)
		If x <> a Then pincode = False
	Next j
	'execute command if pincode is valid
	If pincode = True Then
		If data(5) = ":" Then  'check for command separator
		'commands:  1/0 - on/off of relay output
		'T/F - Til/fra of alarm/inputs
		'r   - reboot system, start from 0000
		'v   - send version number of firmware
		'?   - Status request (relay and alarm)

			If data(6) = "1" Then  'relay on
				relay = 1
				Gosub init_sms
				Hserout "Udgang: TIL", 0x1a
			Endif
			If data(6) = "0" Then  'relay off
				relay = 0
				Gosub init_sms
				Hserout "Udgang: FRA", 0x1a
			Endif
			If data(6) = "F" Or data(6) = "f" Then  'Disable inputs
			'disable inputs
				armed = 0
				Gosub init_sms
				Hserout "Alarm: FRA", 0x1a
			Endif
			If data(6) = "T" Or data(6) = "t" Then  'Enable inputs
			'enable input
				Gosub init_sms
				If hw_enable = 0 Then
					Hserout "Valg ej muligt", 0x1a
				Else
					armed = 1
					Hserout "Alarm: TIL", 0x1a
				Endif
			Endif

			If data(6) = "?" Then  'command for system status
				Gosub init_sms
				If relay = 1 Then
					Hserout "Udgang: TIL", CrLf
				Else
					Hserout "Udgang: FRA", CrLf
				Endif
				If armed = 0 Then
					Hserout "Alarm: FRA"
				Else
					Hserout "Alarm: TIL"
				Endif
				Hserout 0x1a
			Endif
			If data(6) = "v" Then  'send version no.
				Gosub init_sms
				Hserout "GSM-SIO4 v0.b", 0x1a
			Endif
			If data(6) = "r" Then  'reboot system
				Goto main
			Endif
				
		Endif
	Endif
	'clear buffer
	For k = 0 To 40 Step 1
		data(k) = 0xff
	Next k
Endif
Return                                            


get_number:
'****************
'read phone number from SIM card
'read from serial port and search after " and + and store from + to last " in buffer.
'respond if no. found: +CPBF: 1,"+45xxxxxxxx",145,"PRIMARY!"
'respond if not found: ???
'if j=0 no data found. Otherwise j is the number of chars in the buffer.

j = 0
i = 0
k = 0
startmark = False
loop_nr:
	Gosub hserget2
	If serdata > 0 Then
		temp = LookUp(0x22, "+"), k  'search for " and then for +
		If serdata = temp Then
			k = k + 1
			If k = 2 Then
				startmark = True
			Endif
		Endif
		If serdata = 0x22 And startmark = True Then
			startmark = False
		Endif
		If startmark = True Then
			data(j) = serdata  'store data in buffer
			If j = 64 Then
				j = 0
			Else
				j = j + 1
			Endif
		Endif
	Endif
	i = i + 1
	If i = 10000 Then Return  'timeout
Goto loop_nr
Return                                            

modem_ready:
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
'sends AT command to modem and wait for OK to be received.
'respond will be ERROR or OK. Only character 'k' is checked
modemready = False
Hserout "AT", CrLf
loop_mr:
	Gosub hserget2
	If serdata > 0 Then
		If serdata = "K" Then  'OK received
			modemready = True
		Endif
	Endif
	i = i + 1
	If i = 20000 Then Return  'timeout
Goto loop_mr
Return                                            

waiting:
'*************************************
WaitMs 350
Return                                            



hserget2:
'*******************************************
'serial input routine with error handling.
'returns 0 in variable "serdata" if no data read
ASM:ser_in: btfsc rcsta,oerr
ASM:        goto overerror
ASM:        btfsc rcsta,ferr
ASM:        goto frameerror
ASM:        clrw  'return 0 if no data
ASM:        btfss pir1,rcif
ASM:        goto end_call
ASM:uart_gotit: bcf intcon,gie  'clear gie before read
ASM:        btfsc intcon,gie
ASM:        goto uart_gotit
ASM:        movf rcreg,w
ASM:        bsf intcon,gie
ASM:        goto end_call
ASM:overerror: bcf intcon,gie  'turn gie off
ASM:        btfsc INTCON,GIE
ASM:        goto overerror
ASM:        bcf rcsta,cren
ASM:        movf rcreg,w  'flush fifo
ASM:        movf rcreg,w
ASM:        movf rcreg,w
ASM:        bsf rcsta,cren  'turn cren on, clear oerr flag
ASM:        bsf intcon,gie
ASM:        goto ser_in
ASM:frameerror: bcf intcon,gie
ASM:        btfsc intcon,gie
ASM:        goto frameerror
ASM:        movf rcreg,w
ASM:        bsf intcon,gie
ASM:        goto ser_in
ASM:end_call: movwf serdata
Return                                            



