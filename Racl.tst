#
#	@(#) Racl.tst V3.0 © 2024 by Roman Oreshnikov
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

Tst 1:8	Отсутствует описание сети
	Cfg '
permit ip 1.1.1.1 any
'
	Run $CFG

Tst 1:5	Определен только заголовок
	Cfg '
new ЛВС
'
	Run $CFG

Tst 1:8	Двойной заголовок
	Cfg '
new ЛВС
new Локальная Сеть
'
	Run $CFG

Tst 1:36 Ошибки регистрации МСЭ
	Cfg '
# Fi отсутствует имя
dev
# Fi недопустмое имя МСЭ
dev 0
# Fi зарезервированное имя
dev lt
# Fi недопустмый IP адрес
dev gw 1
# Fi недопустмый IP адрес
dev gw 1/32
# Fi отсутствует описание
dev gw 1.1.1.1
# Ok
dev gw 1.1.1.1 МСЭ
# Fi дубликат
dev gw
# Fi IP адрес используется
dev gw2 1.1.1.1
# Fi gw2 не зарегистрирован
dev GW gw gw2
# Fi 0/0 недопустимое имя
dev GW gw 0/0
'
	Run $CFG

Tst 1:34 Ошибки регистрации ACL
	Cfg '
# Требуется правильное описание МСЭ
dev gw 1.1.1.1 МСЭ
# Fi отсутствует имя ACL
acl
# Fi недопустмое имя ACL
acl $
# Fi пропущено имя МСЭ
acl Acl
# Fi недопустмое имя МСЭ
acl Acl G+W
# Fi МСЭ не зарегистрирован
acl Acl GW
# Fi отсутствует описание
acl Acl gw
# Ok внутренний ACL
acl Acl gw Internal ACL
# Fi дубликат ACL
ACL Acl
# Ok внешний ACL
ACL Inet gw Outside ACL
# Fi регистрация МСЭ после ACL
dev gw2 2.2.2.2 FireWall
'
	Run $CFG

Tst 1:69 Ошибки регистрации сетевого объекта
	Cfg '
# Требуется правильное описание МСЭ
dev gw 1.2.3.4 МСЭ
# требуются зарегистрированные ACL
ACL Out gw Acl входящего в ЛВС трафика
acl Ins gw Acl исходящего из ЛВС трафика
# Fi отсутствует IP
add
# Fi недопустимый IP
add 1.2
# Fi недопустимый IP
add 1.2.3.257
# Fi недопустимый IP
add 1.321.0/24
# Fi отсутствует маска
add 1.2.3.0
# Fi недопустимая маска
add 1/33
# Fi маленькая маска
add 1.2.3.4/24
# Fi недопустимое имя ACL
add 1.1/16 _
# Fi незарегистрированная ACL
add 1.2.3/24 None
# Fi отсутствует описание
add 1.2.3/24 Ins
# Fi резервирование any за ЛВС
add 0/0 - Резерв
# Fi any не может быть сетью ЛВС
add 0/0 Ins ЛВС
# Ok Internet
add 0/0 Out Inet Интернет
# Ok резервирование блока сетей для ЛВС
add 1/8 - Сети ЛВС
# Ok сеть из зарезервированного блока
add 1.2.3/24 Ins DMZ
# Fi повтор
add 1.2.3.0/24 Ins Клиенты
# Fi перекрытие зарегистрированной сети 1.2.3/24
add 1.2/16 Ins Клиенты
# Ok
add 2.0.0.0/24 Out Внешняя сеть
# Fi перекрытие внешней сети
add 2.0.0.0/23 Out Внешняя сеть
# Ok часть внешней сети
add 2.0.0.0/25 Out Внешняя подсеть
# Ok часть внешней сети - внутренняя
add 2.0.0.0/27 Ins Внешняя подсеть
# Fi регистрация ACL после сети
acl Bad gw Bad
'
	Run $CFG

Tst 1:21 Ошибки конфигурации ЛВС
	Cfg '
# Fi нет заголовка
new
dev gw1 1.1.1.1 Ok МСЭ-1 с IP адресом вне ЛВС
dev gw2 2.2.0.0 Fi МСЭ-2 c IP адресом сети и без ACL
ACL Out gw1 Acl входящего в ЛВС трафика
acl Ins gw1 Acl исходящего из ЛВС трафика
add 0/0 Out Internet
add 2/8 - Блок сетей LAN
add 2.2/16 Ins Сеть из блока LAN
new	Заявка №1
; Доступ сервера в Интернет
permit ip 2.2.2.2 any
'
	Run $CFG

Tst 1:82 Ошибки обоснований и правил доступа
	Cfg '
new Test
dev gw 192.168.0.1 МСЭ
acl Lan-1 gw ACL на входе из Lan-1
acl Lan-2 gw ACL на входе из Lan-2
add 192.168.0/24 Lan-1 ЛВС Lan-1
add 192.168.1/24 Lan-2 ЛВС Lan-2
; Fi нет обоснования
permit
# Fi пустое обоснование
new
# Ok
new Обоснование
# Fi регистрация сети после проверки инфраструктуры
add 192.168.2/24 Lan-3 ЛВС Lan-3
# Fi пустое описание
;
; Fi нет протокола
permit
; Fi неизвестный протокол
permit bad
; Fi нет источника
permit ip
; Fi источник не в ЛВС
permit ip 1.1.1.1
; Fi нет приемника
permit ip 192.168.0.2
; Fi приемник не в ЛВС
permit ip 192.168.0.2 1.1.1.1
; Fi ошибка указания порта
permit ip 192.168.0.2 eq 1 192.168.1.2
; Fi ошибка указания порта
permit ip 192.168.0.2 192.168.1.2 eq 1
; Fi ошибка указания порта
permit tcp 192.168.0.2 ll
; Fi ошибка указания порта
permit tcp 192.168.0.2 eq ff
; Fi ошибка указания порта
permit tcp 192.168.0.2 range 1
; Fi ошибка указания порта
permit tcp 192.168.0.2 range 1 1
; Fi ошибка указания порта
permit tcp 192.168.0.2 range 2 1
; Fi недопустимое использование
permit tcp 192.168.0.2 established
; Fi не поддерживается
permit udp 192.168.0.2 192.168.1/24 established
; Fi недопустимое использование
permit tcp 192.168.0.2 eq 1 192.168.1/24 established
; Ok
permit ip 192.168.0.2 192.168.1.2 log
; Fi дубликат
permit ip 192.168.0.2 192.168.1.2
; ?Ok
permit tcp 192.168.0.2 192.168.1.2 eq 0
; Ok
permit tcp 192.168.0.2 192.168.1/24 established
'
	Run $CFG

Tst 1:53 Ошибки регистрации групп и описания объектов
	Cfg '
new Test
dev gw 192.168.0.1 МСЭ
acl Lan-1 gw ACL на входе из Lan-1
acl Lan-2 gw ACL на входе из Lan-2
add 192.168.0/24 Lan-1 ЛВС Lan-1
add 192.168.1/24 Lan-2 ЛВС Lan-2
# Fi нет имени
grp
# Fi недопустимое имя
grp 1a
# Fi пустой список
grp New
# Fi не принадлежит известным сетям
grp Bad 1/8
# Ok
grp New 192.168/23
# Fi дубликат
grp New 1.1.1.1
# Fi незарегистрированное имя члена группы
grp Bad Ok
# Fi дубликат имени члена группы
grp Bad gw gw
# Fi дубликат объекта
grp Bad Lan-1 192.168/24
# Ok
grp Ok Lan-1 gw Lan-2
# Fi отсутствует объект
def
# Fi отсутствует описание
def 192.168.1.1
# Fi объект не принадлежит известным сетям
def 2.2.2.2 host
# Fi у объекта уже есть описание
def 192.168.0.1 gw
# Ok
def 192.168.0.2 Server
'
	Run $CFG

Tst 0:20 ЛВС без выхода в Интернет
	Cfg '
new ЛВС без выхода в Интернет
dev gw 192.168.0.1 МСЭ
acl Lan-1 gw ACL на входе из Lan-1
acl Lan-2 gw ACL на входе из Lan-2
add 192.168.0/24 Lan-1 ЛВС Lan-1
add 192.168.1/24 Lan-2 ЛВС Lan-2
new Обоснование
; правило доступа
permit ip 192.168.0/24 192.168.1.2
permit ip 192.168.1.2 192.168.0/24
'
	Run $CFG

Tst 0:35 ЛВС с выходом в Интернет
	Cfg '
new ЛВС с выходом в Интернет
dev gw	192.168.0.1 МСЭ
ACL out gw ACL Интернет
acl ins gw ACL ЛВС
add 0/0		out	Интернет
add 10/8	-	Local use only
add 172.16/12	-	Local use only
add 192.168/16	-	Local use only
add 1.1.1/24	out	Сеть провайдера
add 1.1.1.2	-	Внешний интерфейс gw
add 192.168/24	ins	ЛВС
new Обоснование
; правило доступа из ЛВС
permit ip 192.168/24 0/0 reflect Input
; правило доступа из Интернет к интерфейсу gw
permit tcp any 1.1.1.2 eq 443
'
	Run $CFG
