#!/bin/bash
#Example of upload API for the ndjson file specified by the argument to $0

EHOST="localhost"
PASSWORD="somePassword" #can be found in container siglasticsearch:/etc/elasticsearch/passwords for user 'elastic'
INDEX="signals"
FILE="signals.ndjson"

if [ "$1" ]; then
	EHOST="$1"
else
	echo "Usage: $0 elasticHostname elasticPassword targetIndex filename.ndjson"
	exit 1
fi

if [ "$2" ]; then
	PASSWORD="$2"
else
	echo "Usage: $0 elasticHostname elasticPassword targetIndex filename.ndjson"
	exit 1
fi

if [ "$3" ]; then
	INDEX="$3"
fi

if [ "$4" ]; then
	FILE="$4"
fi

curl -k -s -u elastic:${PASSWORD} -XPOST http://${EHOST}:9200/${INDEX}/_bulk?pretty\&refresh=true -H "Content-Type: application/x-ndjson" --data-binary @$FILE 2>&1
exit $?
