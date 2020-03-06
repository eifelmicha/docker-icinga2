#!/bin/bash
#
# Check if service is running with systemctl
#
# Roger Sikorski 
# https://github.com/RogerSik/Icinga2-Check-Scripts

#OK=0
#WARNING=1
#CRITICAL=2
#UNKNOWN=3

while getopts s: option
do
case "${option}"
in
s) SERVICE=${OPTARG};;
esac
done

systemctl is-active "$SERVICE".service
