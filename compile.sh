#!/bin/bash

set -e

EXENAME="event_logger"
CFLAGS="-Wall"
OPTCFLAGS="${CFLAGS} -O2"
DBGCFLAGS="${CFLAGS} -ggdb3 -DDEBUG"

rm -f *.exe *.dbg

gcc ${OPTCFLAGS}         event_logger.c cJSON.c -o ${EXENAME}.exe
gcc ${DBGCFLAGS}         event_logger.c cJSON.c -o ${EXENAME}.dbg
gcc ${OPTCFLAGS} -static event_logger.c cJSON.c -o ${EXENAME}.static.exe

strip *.exe
