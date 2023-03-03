#!/bin/bash
#
#Jason Barnett - xasmodeanx@gmail.com
#
#healthcheck.sh
#healthcheck.sh is a simple script that tries to determine if the processes inside your container
#are running correctly or not.  This healthcheck.sh script is run by the docker daemon from the 
#HEALTHCHECK CMD directive in the dockerfile.  healthcheck.sh should perform some operation
#to check status of your processes and then exit with an integer value conveying the status result.
#Common exit statuses: 
#0 - all tests passed and the healthcheck was GOOD
#1 - a test failed and healthcheck was BAD
#2 - some other test failed and healthcheck was BAD
#etc.

KIBANA_SYSTEM_PASSWORD="`cat /usr/share/elasticsearch/data/passwords | grep 'PASSWORD kibana_system' | awk '{print $4}'`"
ELASTIC_PASSWORD="`cat /usr/share/elasticsearch/data/passwords | grep 'PASSWORD elastic = ' | awk '{print $4}'`"

CHECKCMD="curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cat/health"
CHECKCMDRESULT="`${CHECKCMD} 2>&1`"
CHECKCMDSTATUSRESULT="$?"

echo "${CHECKCMD} : ${CHECKCMDSTATUSRESULT} : ${CHECKCMDRESULT}"

exit ${CHECKCMDSTATUSRESULT}

