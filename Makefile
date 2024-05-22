#
#	@(#) Makefile V3.0 © 2024 by Roman Oreshnikov
#
#	Сценарий работ по созданию ACL и их загрузки на МСЭ
#

# Рабочий каталог Racl
WRK	:= Racl.d

# Исходные файлы описания ЛВС, обоснований и соответствующих им правил
CFG	:= Racl.cfg

# Имя файла HTML-отчета
HTM	:= $(WRK)/Racl.htm

# Взаимодействие с МСЭ:
ADM	:= 192.168.0.1	# IP адрес административного сервера
EXT	:= .cfg		# Суффикс конфигурационных файлов МСЭ
DST	:= TFTP.d	# Каталог измененных ACL в иерархии TFTP-сервера
NEW	:= 		# Каталог измененных ACL относительно корня TFTP-сервера
#RSH	:= rsh		# Утилита взаимодействия с МСЭ
RSH	:= sh Rsh
SRC	:= CFG.d	# Каталог конфигурационных файлов МСЭ

### Ниже изменять на свой риск!

ACL	:= $(WRK)/Racl.acl	# Готовность ACL для загрузки
LOG	:= $(WRK)/Rchk.log	# Протокол тестирования
NOW	:= $(WRK)/Racl.now	# Эталонные ACL построенные Racl
OLD	:= $(WRK)/Racl.old	# Актуальные ACL из конфигураций МСЭ
UPD	:= $(WRK)/Racl.upd	# Загрузка ACL на МСЭ выполнена
USE	:= $(WRK)/Racl.use	# Список МСЭ

# Дистрибутивный архив
TAR	:= Racl-$(shell sed '/@(#)/!d;s/.*V\([0-9.]*\).*/\1/' README).tar.xz
# Список файлов архива
LST	:= Makefile README README.md Racl Racl.tst Rchk Cisco2Racl Racl2Cisco\
		Rsh Racl.cfg Racl.local.cfg Racl.inet1.cfg Racl.inet2.cfg

.PHONY:	acl actual check clean config diff dist install help report test

acl:	actual $(ACL)
	@[ -f $(UPD) ] && echo "Активные ACL МСЭ соответствуют эталонным" ||\
	{ echo "!!! Требуется загрузка измененных ACL на МСЭ";\
	echo "*** Выполните 'make install'"; }

actual: $(NOW)
	@set -e; S=$(strip $(SRC)) E=$(strip $(EXT)) D=$(strip $(OLD));\
	while read N I; do [ $$S/$$N$$E -ot $$D ] || L=$$L\ $$N; done <$(USE);\
	[ -n "$$L" ] || exit 0;\
	echo ">>> Выборка ACL из сохраненных конфигураций МСЭ";\
	for N in $$L; do F=$$S/$$N$$E; echo "Извлечение ACL из $$F";\
		[ -f $$F ] || { echo "!!! $$F - отсутствует"; L=; break; };\
		sh Cisco2Racl $$F >>$$D;\
	done; [ -z "$$L" ] || { rm -f $(ACL) $(UPD); exit; };\
	echo "*** Выполните 'make config' для загрузки ACL на МСЭ"; exit 1

check:	$(USE)

clean:
	@echo ">>> Удаление временных файлов и каталогов";\
	for D in $(WRK) $(SRC) $(DST); do\
		case /$$D/ in //|/*/*/|/./|/../|*/-*);; *) L="$$L $$D";; esac;\
	done;\
	rm -rf $$L $(LOG) $(NOW) $(USE) $(HTM) $(OLD) $(ACL) $(UPD)

config:	$(NOW)
	@echo ">>> Получение текущих конфигураций МСЭ";\
	E=$(strip $(EXT)); S=$(strip $(SRC));\
	while read N I; do F=$$S/$$N$$E;\
		echo "$(strip $(RSH)) $$N \"show running-config\" >$$F";\
		$(RSH) $$I "show running-config" >$$F~ &&\
		mv $$F~ $$F || { rm -f $$F~; exit 1; };\
	done <$(USE)

diff:	$(ACL)
	@echo ">>> Различия между актуальными ACL и эталонными";\
	diff -u $(OLD) $(NOW) || :

dist:
	@echo ">>> Создание дистрибутивного архива $(TAR)";\
	D=$(TAR) D=$${D%.tar*}; mkdir $$D; cp $(LST) $$D;\
	tar -caf $(TAR) --remove-files $$D

install: $(UPD)

help:
	@echo "  Доступные цели (по умолчанию - acl):";\
	echo "acl     - Проверить активные ACL на соответствие эталонным";\
	echo "actual  - Получить активные ACL из сохраненных конфигураций МСЭ";\
	echo "check   - Проверить наличие необходимых каталогов";\
	echo "clean   - Удалить временные файлы/каталоги";\
	echo "config  - Получить текущие конфигурации МСЭ";\
	echo "diff    - Вывести различия активных ACL с вновь построенными";\
	echo "dist    - Создать дистрибутивный архив: $(TAR)";\
	echo "install - Загрузить эталонные ACL на соответствующие МСЭ";\
	echo "help    - Вывести справку по целям";\
	echo "report  - Получить HTML-отчёт: $(HTM)";\
	echo "test    - Выполнить автотест работоспособности: Racl.tst";\
	echo "  Доступные примеры конфигураций:";\
	echo "CFG=Racl.local.cfg - ЛВС без выхода в Интернет";\
	echo "CFG=Racl.inet1.cfg - ЛВС с выходом в Интернет (inspect)";\
	echo "CFG=Racl.inet2.cfg - ЛВС с выходом в Интернет (reflect)"

report: $(HTM)

test:	$(USE)
	@echo ">>> Выполнение автотеста работоспособности 'Racl'";\
	sh ./Rchk -l$(LOG) -r Racl Racl.tst

$(ACL): $(OLD)
	@echo ">>> Проверка изменений в ACL"; set -e;\
	sh Racl2Cisco -d $(DST) $(OLD) $(NOW) && touch $(ACL)

$(NOW):	$(USE) $(CFG)
	@echo ">>> Создание эталонных ACL для текущей конфигурации";\
	sh Racl -l$(USE) -r$(HTM) $(CFG) >$(NOW) || { rm $(NOW); exit 1; }

$(HTM): $(USE) $(CFG)
	@echo ">>> Создание HTML-отчёта $(HTM)";\
	sh Racl -nr$(HTM) $(CFG)

$(UPD): $(ACL)
	@echo ">>> Загрузка измененных ACL"; set -e;\
	A=$(strip $(ADM)) D=$(strip $(DST)) P=$(strip $(NEW)); \
	while read N I; do F=$$D/$$N; [ -f "$$F" ] || continue;\
		S="copy tftp://$$A/$${P:+$$P/}$$N running-config";\
		echo "$(strip $(RSH)) $$N \"$$S\"";\
		$(RSH) $$I "$$S" && rm $$F;\
	done <$(USE); cp $(NOW) $(OLD); touch $(ACL) $(UPD)

$(USE):
	@echo ">>> Проверка наличия необходимых каталогов";\
	for D in WRK/$(WRK) SRC/$(SRC) DST/$(DST); do N=$${D%/*} D=$${D#*/};\
		case /$$D/ in\
		//) echo "!!! $$N - имя каталога не задано"; exit 1;;\
		*//*|*/-*|*[!0-9A-Za-z.\/_-]*)\
			echo "!!! '$$D' - недопустимое имя для $$N";\ exit 1;;\
		/*/*/) [ -d $$D ] && continue;\
			echo "!!! $$D - каталог отсутствует"; exit 1;;\
		*) [ -d $$D ] || mkdir $$D || exit 1;;\
		esac;\
	done; [ -f $(USE) ] || touch $(USE)
