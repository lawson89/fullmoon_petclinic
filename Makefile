# /*─────────────────────────────────────────────────────────────────╗
# │ To the extent possible under law, Jared Miller has waived        │
# │ all copyright and related or neighboring rights to this file,    │
# │ as it is written in the following disclaimers:                   │
# │   • http://unlicense.org/                                        │
# ╚─────────────────────────────────────────────────────────────────*/
.PHONY: all clean test log ls log start start-daemon restart-daemon stop-daemon

# Change redbean to whatever you want
PROJECT=redbean
REDBEAN=${PROJECT}.com
REDBEAN_VERSION=2.2
# leave empty for default, or use one of tiny-, asan-, original-, static-, unsecure-, original-tinylinux-
# asan mode currently not working on M1 Macs
#REDBEAN_MODE=
REDBEAN_MODE=asan-
REDBEAN_DL=https://redbean.dev/redbean-${REDBEAN_MODE}${REDBEAN_VERSION}.com

SQLITE3=sqlite3.com
SQLITE3_DL=https://redbean.dev/sqlite3.com
ZIP=zip
ZIP_DL=https://redbean.dev/zip.com
UNZIP=unzip
UNZIP_DL=https://redbean.dev/unzip.com
DEFINITIONS=definitions/redbean.lua
DEFINITIONS_DL=https://raw.githubusercontent.com/jart/cosmopolitan/2.2/tool/net/definitions.lua

NPD=--no-print-directory

all: download add

download: ${REDBEAN} ${SQLITE3} ${UNZIP} ${DEFINITIONS}

${REDBEAN}.template:
	curl -s ${REDBEAN_DL} -o $@ -z $@ && \
		chmod +x $@

${REDBEAN}: ${REDBEAN}.template
	cp ${REDBEAN}.template ${REDBEAN}

${SQLITE3}:
	curl -s ${SQLITE3_DL} -o $@ -z $@
	chmod +x ${SQLITE3}

${ZIP}:
	# curl -s ${ZIP_DL} -o $@ -z $@
	# chmod +x ${ZIP}

${UNZIP}:
	#curl -s ${UNZIP_DL} -o $@ -z $@
	#chmod +x ${UNZIP}

${DEFINITIONS}:
	mkdir -p definitions
	curl -s ${DEFINITIONS_DL} -o $@ -z $@

add: ${ZIP} ${REDBEAN}
	cp -f ${REDBEAN}.template ${REDBEAN}
	cd srv/ && ${ZIP} -r ../${REDBEAN} `ls -A`

ls: ${UNZIP}
	@./${UNZIP} -vl ./${REDBEAN} | grep -v \
		'usr/\|.symtab'

log: ${PROJECT}.log
	tail -f ${PROJECT}.log

start: add ${REDBEAN}
	./${REDBEAN} -vv

start-daemon: ${REDBEAN}
	@(test ! -f ${PROJECT}.pid && \
		./${REDBEAN} -vv -d -L ${PROJECT}.log -P ${PROJECT}.pid && \
		printf "started $$(cat ${PROJECT}.pid)\n") \
		|| echo "already running $$(cat ${PROJECT}.pid)"
    
start-daemon-silent: ${REDBEAN}
	@(test ! -f ${PROJECT}.pid && \
		./${REDBEAN} -s -d -P ${PROJECT}.pid && \
		printf "started $$(cat ${PROJECT}.pid)\n") \
		|| echo "already running $$(cat ${PROJECT}.pid)"    

restart-daemon:
	@(test ! -f ${PROJECT}.pid && \
		./${REDBEAN} -vv -d -L ${PROJECT}.log -P ${PROJECT}.pid && \
		printf "started $$(cat ${PROJECT}.pid)") \
		|| kill -HUP $$(cat ${PROJECT}.pid) && \
		printf "restarted $$(cat ${PROJECT}.pid)\n"

stop-daemon: ${PROJECT}.pid
	@kill -TERM $$(cat ${PROJECT}.pid) && \
		printf "stopped $$(cat ${PROJECT}.pid)\n" && \
		rm ${PROJECT}.pid \
    
benchmark:
	wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8000/

clean:
	rm -f ${PROJECT}.log ${PROJECT}.pid ${REDBEAN} ${REDBEAN}.template ${SQLITE3} ${ZIP} ${UNZIP} ${DEFINITIONS}
	[ "$(ls -A definitions)" ] || rm -rf definitions
