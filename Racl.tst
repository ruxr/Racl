#
#	@(#) Racl.tst V5.0 © 2024 by Roman Oreshnikov
#
#	Сценарий автотеста комплекта программ Racl
#
CFG=	# Имя текущего входного файла
#
# Инструментарий
#
Cfg() {
	[ $# = 2 ] && shift && CFG=Tst.cfg || CFG=Tst$NUM.cfg
	echo "# Тестовый файл $CFG$@" | sed '${/^$/d}' >$CFG
	sed = $CFG | sed 'N;s/^/     /;s/ *\(.\{5,\}\)\n/\1 /'
}
#
# Собственно тесты
#
Tst 0:20 Получение справки
	Run -h

Tst 1:3	Неизвестный ключ запуска
	Run -X

Tst 1:2	Повтор ключа
	Run -n -n

Tst 1:2	Недопустимый параметр ключа
	Run -r .

Tst 1:2	Входной файл не задан
	Run

Tst 1:2	Входной файл задан, но отсутствует
	Run NoFile

Tst 1:4	Пустой конфигурационный файл
	Cfg '
'
	Run $CFG

Tst 1:5	Определен только заголовок
	Cfg '
ЛВС
'
	Run $CFG

Tst 1:7	Двойной заголовок
	Cfg '
ЛВС
Локальная Сеть
'
	Run $CFG

Tst 1:40 Ошибки регистрации сетей
	Cfg '
# Fi недопустимый IP
1.2
# Fi недопустимый IP
1.2.3.257
# Fi недопустимый IP
1.321.0/24
# Fi недопустимая маска
1/33
# Fi маленькая маска
1.2.3.4/24
# Fi недопустимое имя ACL
1.1/16 _
# Fi отсутствует описание
1.2.3/24 Ins
# Ok резервирование any за ЛВС
0/0 - Резерв
# Fi Дубликат
0.0/0 Out Inet Интернет
# Ok резервирование блока сетей для ЛВС
1/8 - Сети ЛВС
# Ok сеть из зарезервированного блока
1.2.3/24 Ins DMZ
# Fi повтор
1.2.3.0/24 Ins Клиенты
# Fi перекрытие зарегистрированной сети 1.2.3/24
1.2/16 Ins Клиенты
'
	Run $CFG

Tst 1:30 Ошибки объявлений МСЭ
	Cfg '
Test
# Требуются IP
1.1/16 - Lan
# Fi недопустмое имя для МСЭ
any
# Fi недопустмый IP адрес
gw 1
# Fi недопустмый IP адрес
gw 300.1.1.1
# Ok
gw 1.1.1.1
# Fi дубликат
gw 2.2.2.2
# Fi нет подходящей сети
gw2 2.2.2.2
# Fi gw2 не зарегистрирован
GW gw gw2
# Fi 0/0 недопустимое имя
GW gw 0/0
'
	Run $CFG

Tst 1:35 Ошибки объявления ACL
	Cfg '
Test
# Требуются IP
0/0 OUT Inet
1.1/16 ACL Lan
# Требуется МСЭ
gw 1.1.1.1
# Fi недопустмое имя ACL
any
# Fi ACL не зарегистрирован
- Acl
# Fi пропущено имя МСЭ
- ACL
# Fi недопустмое имя МСЭ
- ACL G+W
# Fi МСЭ не зарегистрирован
- ACL GW
# Fi отсутствует описание
- ACL gw
# Ok внутренний ACL
- ACL gw Internal ACL
# Fi дубликат ACL
- ACL gw Dublicat
# Ok внешний ACL
+ OUT gw Outside ACL
'
	Run $CFG

Tst 1:23 Ошибки конфигурации ЛВС
	Cfg '
# Fi нет заголовка
0/0 - Internet
10/8 - Блок сетей LAN
10/16 Out Внешняя Сеть
10.10/24 Ins Сеть из блока LAN
10.0.0.1 - g--w.local
gw 10.10.0.0 10.0.0.1
+ Out gw Acl входящего в ЛВС трафика
- Ins gw Acl исходящего из ЛВС трафика
- Bad gw Не зарегистрирована
Заявка №1
'
	Run $CFG

Tst 1:70 Ошибки обоснований и правил доступа
	Cfg '
Test
192.168.0/24 Lan-1 ЛВС Lan-1
192.168.1/24 Lan-2 ЛВС Lan-2
192.168.0.1 - gw.local
gw 192.168.0.1
- Lan-1 gw ACL на входе из Lan-1
- Lan-2 gw ACL на входе из Lan-2
; Fi нет обоснования
pass
# Ok
Обоснование
; Fi нет протокола
pass
; Fi неизвестный протокол
pass bad
; Fi нет источника
pass ip
; Fi источник не в ЛВС
pass ip 1.1.1.1
; Fi нет приемника
pass ip 192.168.0.2
; Fi ошибка указания порта
pass ip 192.168.0.2 eq 1 192.168.1.2
; Fi ошибка указания порта
pass ip 192.168.0.2 192.168.1.2 eq 1
; Fi ошибка указания порта
pass tcp 192.168.0.2 ll
; Fi ошибка указания порта
pass tcp 192.168.0.2 eq ff
; Fi ошибка указания порта
pass tcp 192.168.0.2 range 1
; Fi ошибка указания порта
pass tcp 192.168.0.2 range 1 1
; Fi ошибка указания порта
pass tcp 192.168.0.2 range 2 1
; Fi недопустимое использование
pass tcp 192.168.0.2 established
; Fi не поддерживается
pass udp 192.168.0.2 192.168.1/24 established
; ?Ok
pass tcp 192.168.0.2 eq 1 192.168.1/24 established
; Ok
pass ip 192.168.0.2 192.168.1.2
; Fi дубликат
pass ip 192.168.0.2 192.168.1.2
; ?Ok
pass tcp 192.168.0.2 192.168.1.2 eq 0 log
; Ok
pass tcp 192.168.0.2 192.168.1/24 established
'
	Run $CFG

Tst 1:43 Ошибки регистрации групп и описания IP-адресов
	Cfg '
Test
192.168.0/24 Lan-1 ЛВС Lan-1
192.168.1/24 Lan-2 ЛВС Lan-2
192.168.0.1 - gw.local
gw 192.168.0.1
- Lan-1 gw ACL на входе из Lan-1
- Lan-2 gw ACL на входе из Lan-2
# Fi недопустимое имя
1a
# Fi пустой список
New
# Fi не принадлежит известным сетям
Bad 1/8
# Ok
New 192.168/23
# Fi дубликат
New 1.1.1.1
# Fi незарегистрированное имя члена группы
Bad Ok
# Ok
Ok Lan-1 gw Lan-2
# Fi отсутствует описание
192.168.1.1
# Fi IP не принадлежит известным сетям
2.2.2.2 host
# Fi у IP уже есть описание
192.168.0.1 gw
# Ok
192.168.0.2 Server
'
	Run $CFG

Tst 0:21 ЛВС без выхода в Интернет
	Cfg '
ЛВС без выхода в Интернет
192.168.0/24 Lan-1 ЛВС Lan-1
192.168.1/24 Lan-2 ЛВС Lan-2
192.168.0.1 - gw.local
gw 192.168.0.1
- Lan-1 gw ACL на входе из Lan-1
- Lan-2 gw ACL на входе из Lan-2
Обоснование
; правило доступа
pass ip 192.168.0/24 192.168.1.2
pass ip 192.168.1.2 192.168.0/24
'
	Run $CFG

Tst 0:36 ЛВС с выходом в Интернет
	Cfg '
ЛВС с выходом в Интернет
0/0		out	Интернет
10/8		-	Local use only
172.16/12	-	Local use only
192.168/16	-	Local use only
1.1.1/24	out	Сеть провайдера
1.1.1.2		-	gw.inet
192.168/24	ins	ЛВС
192.168.0.1	-	gw.local
gw 192.168.0.1
+ out gw ACL Интернет
- ins gw ACL ЛВС
Обоснование
; правило доступа из ЛВС
pass ip 192.168/24 0/0 reflect Input
; правило доступа из Интернет к интерфейсу gw
pass tcp any 1.1.1.2 eq 443
'
	Run $CFG
