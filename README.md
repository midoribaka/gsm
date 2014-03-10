GSM сигнализация на pic16f628a.

Принцип работы:

 При включении тумблера S1, светодиод VD4 моргнув два раза тухнет, затем идёт минутная задержка, что бы вы успели выйти и закрыть дверь. После светодиод моргает ещё два раза и контроллер переходит в спящий режим, разбудить его должен разрыв охранного шлейфа.
 Когда разрывается охранная линия, VD1 зажигается и не погаснет пока будет разорван шлейф – он индицирует режим дозвонов на номера пользователя. Но дозвон начинается спустя 20 секунд – за это время пользователь должен отключить устройство выключателем S1. В этом состоит "фишка”, чтобы не наворачивать устройство дополнительными выключателями на лестничной площадке. Ворюгу, если залезет, эти 20 секунд не спасут. На схеме VD2 применить можно 1N4148, а для  VD3 - 1N4007 или подобные.
 Номера нужно записывать на сим карту в первые ячейки, на английском языке. можно назвать их №1 и №2. В телефоне нужно отключить все блокировки. 
