#!/bin/bash
#
# Count files in directory and gives OK / WARNING / CRITICAL
#
# Roger Sikorski 
# https://github.com/RogerSik/Icinga2-Check-Scripts
#
# Usage (Example)
# ./check_files_count.sh -p / -w 10 -c 20
#

OPTS=`getopt -o p:w:c: --long path:,warning:,critical: -- "$@"`
eval set -- "$OPTS"

while true
do
  case "$1" in
    -p|--path)
      path="$2"
      shift 2
      ;;
    -w|--warning)
      warning="$2"
      shift 2
      ;;
    -c|--critical)
      critical="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
     *)
      echo "Internal error!"
      exit 1
  esac
done

RESULT=$(ls -p $path | grep -v $path | wc -l)

if [[ $RESULT -gt $critical ]]
        then
                echo "CRITICAL - $RESULT files counted."
                exit 2

elif [[ $RESULT -gt $warning ]]
        then
                echo "WARNING - $RESULT files counted."
                exit 1
else
                echo "OK - $RESULT files counted."
                exit 0
fi
