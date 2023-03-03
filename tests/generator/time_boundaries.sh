#!/bin/bash

STARTTIME="Feb 1 00:00:00 MST 2023"
echo -n "${STARTTIME}: "
date --date="${STARTTIME}" "+%s"

ENDTIME="Mar 3 00:00:00 MST 2023"
echo -n "${ENDTIME}: "
date --date="${ENDTIME}" "+%s"
