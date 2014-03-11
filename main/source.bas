'**********************************
'GSM alarm system
'**********************************

'настройка портов и направления контактов
TRISA = %11110110
TRISB = %01011111  'выход RS232 должен быть определен как вход, из-за драйвера ввода-вывода

'Declare variables
Dim i As Word
Dim j As Byte
Dim k As Byte
Dim x As Byte
Dim y As Byte
Dim n As Byte
Dim a As Byte

Dim temp As Byte
Dim data(64) As Byte  'буфер
Dim serdata As Byte

Dim startmark As Bit
Dim quote As Bit
Dim pincode As Bit
Dim smsreceived As Bit
Dim modemready As Bit

Dim check_sms_count As Byte  'Количество секунд до следующей проверки входящих СМС
Dim alarmcount As Byte  'Количество секунд до отключения выхода
Dim delaycount As Byte  'Количество задержек в секунду

Dim hour As Byte  'Переменные для внутренних часов
Dim min As Byte
Dim sec As Byte

Dim hw_enable_status As Bit
Dim armed As Bit  'Если вход включен = 1

Dim z1trigged As Bit  'Устанавливается, если зона активировалась
Dim z2trigged As Bit  'Устанавливается, если зона активировалась
Dim z3trigged As Bit  'Устанавливается, если зона активировалась
Dim z4trigged As Bit  'Устанавливается, если зона активировалась

Dim pwr_status As Bit
Dim powerfailure As Bit


'Определение портов ввода-вывода
'не забыть установить TRISA и TRISB согласно настройкам ввода-вывода

Symbol hw_enable = PORTA.2  'high = входы активированы
Symbol zone1 = PORTB.4  'вход: зона 1, low = активирована
Symbol zone2 = PORTB.3  'вход: зона 1, low = активирована
Symbol zone3 = PORTB.0  'вход: зона 1, low = активирована
Symbol zone4 = PORTA.4  'вход: зона 1, low = активирована
Symbol aux_out = PORTA.0  'Порт сирены
Symbol relay = PORTA.3  'Релейный выход
Symbol led = PORTB.5  'Светодиодный индикатор состояния
Symbol pwr_sense = PORTA.1  'Вход для контроля мощности



'**** Основная программа ****
main:
'отключить компаратор в RA0-3
	ASM:        MOVLW 0x07
	ASM:        MOVWF CMCON
relay = 0
aux_out = 0

WaitMs 2000  'Подождать, пока система стабилизируется (для драйверов RS232)

'Инициализировать серийный порт HW - порт, используемый модемом
Hseropen 9600

'UART-специфичная инициализация
ASM:        bcf status,rp0
ASM:        bsf rcsta,spen
ASM:        bcf rcsta,rx9
ASM:        bcf rcsta,sren
ASM:        bsf rcsta,cren
ASM:        bcf rcsta,ferr
ASM:        bcf rcsta,rx9d
'сброс перифирийных флагов
ASM:        clrf pir1
'сброс UART-приемника
ASM:        movf RCREG,W
ASM:        movf RCREG,W
ASM:        movf RCREG,W
'инициализация флага txif
ASM:        movlw 0
ASM:        movwf txreg

'запретить прерывания
ASM:        clrf pie1


Define SEROUT_DELAYUS = 5000
'SW serial port TX PORTB.6
'SW serial port RX PORTB.7

'**** Инициализация модема *********
start:
'Послать AT-команду модему и проверить ответ. Повторять, пока ответ не будет получен.
led = 1
Gosub modem_ready
If modemready = True Then
	'инициализация модема
	Hserout "ate0", CrLf  'отключить ответы модема
	Gosub waiting
	Hserout "at+cpms=", 0x22, "SM", 0x22, CrLf  'использовать память СИМ-карты
	Gosub waiting
	Hserout "at+cnmi=0,0,0,0", CrLf  'Стандартное значение.
	WaitMs 500
	Hserout "AT+CMGF=1"  'установить текстовый режим для СМС
	Gosub waiting
	Hserout "at+cmgd=1"  'удалить сообщение, сохраненное в первой ячейке
	Gosub waiting
Else
	Goto start
Endif

'прочитать номер телефона
Gosub waiting
read_first_phoneno:
Hserout "at+cpbf=", 0x22, "PRI", 0x22, CrLf
Gosub get_number
If j > 0 Then
	Write 0, j
	j = j - 1  'количество цифр
	For k = 0 To j Step 1
		temp = data(k)
		n = k + 1
		Write n, temp  'сохранить номер в EEEPROM
	Next k
Else
	WaitMs 1000
	Goto read_first_phoneno
Endif




'********** Основной цикл ******************
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
	WaitMs 250
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
'все операции с временем основаны на счетчиках
If delaycount = 0 Then
	'все таймеры/счетчики в секундах
	If check_sms_count > 0 Then
		check_sms_count = check_sms_count - 1
	Endif
	If alarmcount > 0 Then
		alarmcount = alarmcount - 1
	Endif
	'часы с момента включения
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
	delaycount = 4  'один пункт - 250 mS
Else
	delaycount = delaycount - 1
Endif
Return                                            

check_arming:
'********************************
'hw = 1 (открыто) -> hw_status = 0/armed = 0, armed 0 -> 1, hw_status 0->1
'hw = 0 -> процедура не работает, armed = 0, сирена отключена

If hw_enable <> hw_enable_status Then
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
'проверять зоны при каждом сканировании
If armed = 1 Then
		If zone1 = 1 Then
			If z1trigged = False Then
			'зона активирована
				z1trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Activity in zone 1!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z1trigged = False
		Endif
		If zone2 = 0 Then
			If z2trigged = False Then
			'зона активирована
				z2trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Activity in zone 2!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z2trigged = False
		Endif
		If zone3 = 0 Then
			If z3trigged = False Then
			'зона активирована
				z3trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Activity in zone 3!", 0x1a
				alarmcount = 180
				Gosub waiting
			Endif
		Else
			z3trigged = False
		Endif
		If zone4 = 1 Then
			If z4trigged = False Then
			'зона активирована
				z4trigged = True
				aux_out = 1
				Gosub init_sms
				Hserout "Activity in zone 4!", 0x1a
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
	'отправить СМС если изменилось
	Gosub init_sms
	If pwr_sense = False Then
	'питание потеряно
		Hserout "Power is lost"
	Else
	'питание восстановлено
		powerfailure = True
		Hserout "Power restored"
	Endif
	Hserout 0x1a  'Ascii 26
	pwr_status = pwr_sense
Endif
Return                                            


update_siren:
'******************************
'тревога, если система в режиме охраны (alarmcount будет установлен только в этом случае)
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
'проверять входящие сообщения каждые 10 секунд
If check_sms_count = 0 Then
		Toggle led
		Gosub check_for_message  'проверить, и если сообщение получено
		If smsreceived = True Then
			Hserout "AT", CrLf
			Gosub waiting
			Hserout "at+cmgd=1", CrLf  'удалить сообщение
			Gosub waiting
			Hserout "at+cmgd=1", CrLf  'удалить сообщение
			Gosub waiting
		Endif
		Gosub check_command
		Toggle led
		check_sms_count = 8  'установить число тактов до следующей проверки
	Endif
Return                                            


init_sms:
'*******************************
'отправить строку инициализации модему
	Toggle led
	Hserout "AT", CrLf
	Gosub waiting
	'send SMS
	Hserout "at+cmgs=", 0x22
	Read 0, temp  'посчитать количество цифр в телефонном номере
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
'проверить сообщение в первой ячейке
'ответить:
'если сообщение отсутствует:
'+CMS ERROR: 321
'если сообщение есть:
'+CMGR: "REC UNREAD","+45xxxxxxxx",,"dd/mm/yy,hh:mm:ss+08"
'#1268:0'
'считать информацию и записать в буфер, если '#' найден. В j хранится количество символов.
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
		'проверить, если символ есть - это не сообщение об ошибке
		If serdata = 0x22 Then
			smsreceived = True
		Endif
		If serdata = "#" And smsreceived = True Then
			startmark = True
		Endif
		If startmark = True Then
			data(j) = serdata  'записать информацию в буфер
			If j = 64 Then  'обработать переполнение буфера
				j = 0
			Else
				j = j + 1
			Endif
		Endif
	Endif
	i = i + 1
	If i = 10000 Then Return  'таймаут
Goto loop
Return                                            

check_command:
'****************************
If j > 0 Then  'буфер содержит данные
	j = j - 1
	'проверить пин-код в команде
	'пин-код - четыре цифры после символа "#" в СМС, сохраненном в data().
	'это число сравнивается с последними четырьмя числами телефонного номера,
	'хранящегося в EEPROM.
	pincode = True
	Read 0, x  'посчитать количество цифр в номере
	y = x - 4  'отсчитать стартовую позицию для сравнения
	For j = 1 To 4 Step 1
		y = y + 1  'высчитать относительное смещение
		Read y, a  'считать цифру
		x = data(j)
		If x <> a Then pincode = False
	Next j
	'выполнить команду если пин-код подходит
	If pincode = True Then
		If data(5) = ":" Then  'проверить наличие разделителя
		'команды:  1/0 - включить/выключить релейный выход
		'T/F - включить/выключить of сигнализацию/входы
		'r   - перезапустить систему, начать с 0000
		'v   - отправить версию прошивки
		'?   - запрос отчета (реле и сигнализация)

			If data(6) = "1" Then  'включить реле
				relay = 1
				Gosub init_sms
				Hserout "Output is ON", 0x1a
			Endif
			If data(6) = "0" Then  'отключить реле
				relay = 0
				Gosub init_sms
				Hserout "Output is OFF", 0x1a
			Endif
			If data(6) = "F" Or data(6) = "f" Then  'отключить входы
				armed = 0
				Gosub init_sms
				Hserout "Alarm is OFF", 0x1a
			Endif
			If data(6) = "T" Or data(6) = "t" Then  'включить входы
				Gosub init_sms
				If hw_enable = 0 Then
					Hserout "Сan not be performed", 0x1a
				Else
					armed = 1
					Hserout "Alarm is ON", 0x1a
				Endif
			Endif

			If data(6) = "?" Then  'команды проверки состояния системы
				Gosub init_sms
				If relay = 1 Then
					Hserout "Output is ON", CrLf
				Else
					Hserout "Output is OFF", CrLf
				Endif
				If armed = 0 Then
					Hserout "Alarm is OFF"
				Else
					Hserout "Alarm is ON"
				Endif
				Hserout 0x1a
			Endif
			If data(6) = "v" Then  'отправить версию прошивки
				Gosub init_sms
				Hserout "GAS v 0.1", 0x1a
			Endif
			If data(6) = "r" Then  'перезапустить систему
				Goto main
			Endif
				
		Endif
	Endif
	'очистить буфер
	For k = 0 To 40 Step 1
		data(k) = 0xff
	Next k
Endif
Return                                            


get_number:
'****************
'считать номер телефона с СИМ-карты
'считать из последовательного порта и найти после " и +, сохранить в буфер, начиная с + и заканчивая последним "
'ответить, если номер найден: +CPBF: 1,"+45xxxxxxxx",145,"PRIMARY!"
'ответить, если номер не найден: ???
'если j = 0 - данные не найдены. В противном случае, в j хранится количество символов в буфере.

j = 0
i = 0
k = 0
startmark = False
loop_nr:
	Gosub hserget2
	If serdata > 0 Then
		temp = LookUp(0x22, "+"), k  'искать ", затем +
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
			data(j) = serdata  'записать информацию в буфер
			If j = 64 Then
				j = 0
			Else
				j = j + 1
			Endif
		Endif
	Endif
	i = i + 1
	If i = 10000 Then Return  'таймаут
Goto loop_nr
Return                                            

modem_ready:
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
'послать AT-команды в модем, ждать OK
'результатом будет ERROR или OK. Проверяется только символ "K".
modemready = False
Hserout "AT", CrLf
loop_mr:
	Gosub hserget2
	If serdata > 0 Then
		If serdata = "K" Then  'OK получено
			modemready = True
		Endif
	Endif
	i = i + 1
	If i = 20000 Then Return  'таймаут
Goto loop_mr
Return                                            

waiting:
'*************************************
WaitMs 350
Return                                            



hserget2:
'*******************************************
'последовательный ввод с обработкой ошибок
'возвращает 0 в переменной serdata, если данные не прочитаны
ASM:ser_in: btfsc rcsta,oerr
ASM:        goto overerror
ASM:        btfsc rcsta,ferr
ASM:        goto frameerror
ASM:        clrw  'вернуть 0, если нет данных
ASM:        btfss pir1,rcif
ASM:        goto end_call
ASM:uart_gotit: bcf intcon,gie  'очистить gie перед чтением
ASM:        btfsc intcon,gie
ASM:        goto uart_gotit
ASM:        movf rcreg,w
ASM:        bsf intcon,gie
ASM:        goto end_call
ASM:overerror: bcf intcon,gie  'отключить gie
ASM:        btfsc INTCON,GIE
ASM:        goto overerror
ASM:        bcf rcsta,cren
ASM:        movf rcreg,w  
ASM:        movf rcreg,w
ASM:        movf rcreg,w
ASM:        bsf rcsta,cren  'включить cren, очистить oerr
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
