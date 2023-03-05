#!/bin/bash
# Convert raw ndjson, i.e. data only, into elastic formatted ndjson
# inject elastic commands ahead of data lines

if [ -z "$1" ]; then
  echo "$0: <rawdata.ndjson>"
  exit 1
fi

FILE="$1"
if [ ! -r "$1" ]; then
  echo "${FILE} is not readable!"
  exit 2
fi

while read line; do
  echo '{"index" : {}}'
  echo $line
done <${FILE}

#for line in `cat $FILE`; do
#  echo '{"index" : {}}'
#  echo $line
#done
