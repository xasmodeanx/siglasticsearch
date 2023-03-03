#!/bin/bash
#Convert raw ndjson, i.e. data only, into elastic formatted ndjson, i.e. data lines are separated by elastic commands

if [ -z "$1" ]; then
	echo "Usage: $0 filename.ndjson"
elif [ -e "$1" ]; then
	FILE="$1"
else
	echo "File: $1, not found or not accessible."
fi

for line in `cat $FILE`; do echo '{"index" : {}}';echo $line; done
