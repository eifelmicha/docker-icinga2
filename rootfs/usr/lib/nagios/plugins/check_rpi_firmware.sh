#!/bin/bash

readonly EXIT_OK=0
readonly EXIT_WARNING=1
readonly EXIT_CRITICAL=2
readonly EXIT_UNKNOW=3

JUST_CHECK=1 sudo rpi-update 1>/dev/null 2>/dev/null
STATUS=$?

if [ $STATUS -eq 0 ]; then
        echo "OK: Actual firemware"
        exit $EXIT_OK
fi
if [ $STATUS -eq 1 ]; then
        echo "UNKNOW: Unknown error, please check it manually!"
        exit $EXIT_WARNING
fi
if [ $STATUS -eq 2 ]; then
        echo "WARNING: Firmware update required."
        exit $EXIT_WARNING
fi
