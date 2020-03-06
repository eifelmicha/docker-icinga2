#!/bin/bash
# Based on original E-Mail Icinga2 notification

PROG="`basename $0`"
ICINGA2HOST="`hostname`"
CURLBIN="curl"
MX_TXN="`date "+%s"`$(( RANDOM % 9999 ))"

if [ -z "`which $CURLBIN`" ] ; then
  echo "$CURLBIN not found in \$PATH. Consider installing it."
  exit 1
fi

## Function helpers
Usage() {
cat << EOF

Required parameters:
  -d LONGDATETIME (\$icinga.long_date_time\$)
  -e SERVICENAME (\$service.name\$)
  -l HOSTNAME (\$host.name\$)
  -n HOSTDISPLAYNAME (\$host.display_name\$)
  -o SERVICEOUTPUT (\$service.output\$)
  -s SERVICESTATE (\$service.state\$)
  -t NOTIFICATIONTYPE (\$notification.type\$)
  -u SERVICEDISPLAYNAME (\$service.display_name\$)
  -m MATRIXROOM (\$notification_matrix_room_id\$)
  -x MATRIXSERVER (\$notification_matrix_server\$)
  -y MATRIXTOKEN (\$notification_matrix_token\$)

Optional parameters:
  -4 HOSTADDRESS (\$address\$)
  -6 HOSTADDRESS6 (\$address6\$)
  -b NOTIFICATIONAUTHORNAME (\$notification.author\$)
  -c NOTIFICATIONCOMMENT (\$notification.comment\$)
  -i ICINGAWEB2URL (\$notification_icingaweb2url\$, Default: unset)
EOF
}

Help() {
  Usage;
  exit 0;
}

Error() {
  if [ "$1" ]; then
    echo $1
  fi
  Usage;
  exit 1;
}

## Main
while getopts 4:6:b:c:d:e:hi:l:n:o:s:t:u:m:x:y: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    e) SERVICENAME=$OPTARG ;; # required
    h) Help ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) SERVICEOUTPUT=$OPTARG ;; # required
    s) SERVICESTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    u) SERVICEDISPLAYNAME=$OPTARG ;; # required
    m) MATRIXROOM=$OPTARG ;; # required
    x) MATRIXSERVER=$OPTARG ;; # required
    y) MATRIXTOKEN=$OPTARG ;; # required
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Error ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Error ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Error ;;
  esac
done

shift $((OPTIND - 1))

## Check required parameters (TODO: better error message)
if [ ! "$LONGDATETIME" ] \
|| [ ! "$HOSTNAME" ] || [ ! "$HOSTDISPLAYNAME" ] \
|| [ ! "$SERVICENAME" ] || [ ! "$SERVICEDISPLAYNAME" ] \
|| [ ! "$SERVICEOUTPUT" ] || [ ! "$SERVICESTATE" ] \
|| [ ! "$NOTIFICATIONTYPE" ]; then
  Error "Requirement parameters are missing."
fi

## Build the notification message

if [ "$SERVICESTATE" = "CRITICAL" ]
then
        s_color=#FF5566
        ico="☢"

elif [ "$SERVICESTATE" = "WARNING" ]
then
        s_color=#FFAA44
        ico="⚠"

elif [ "$SERVICESTATE" = "UNKNOWN" ]
then
        s_color=#90A4AE
        ico="?"

elif [ "$SERVICESTATE" = "DOWN" ]
then
        s_color=#FF5566
        ico="!"

#else [ "$SERVICESTATE" = "OK" ]
#then
else
        s_color=#44BB77
        ico="✓"
fi

NOTIFICATION_MESSAGE=`cat << EOF
<font color='$s_color'><strong>$ico Service Monitoring on $ICINGA2HOST </strong></font><br>
<strong>$NOTIFICATIONTYPE: &nbsp;&nbsp;&nbsp;&nbsp; $SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is <font color='$s_color'>$SERVICESTATE!</font></strong><br>
<strong>When:</strong> &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; $LONGDATETIME<br>
EOF
`
## Check whether IPv4 / IPv6 was specified.
if [ -n "$HOSTADDRESS" ] && [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>Host:</strong> &ensp; &nbsp;&nbsp;&nbsp;&nbsp; $HOSTNAME<br>
<strong>IPv4:</strong> &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; $HOSTADDRESS / <strong>IPv6:</strong> $HOSTADDRESS6<br>"
elif [ -n "$HOSTADDRESS" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>Host:</strong> &ensp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; $HOSTNAME / $HOSTADDRESS<br>"
elif [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>Host:</strong> &ensp; &nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp; $HOSTNAME / $HOSTADDRESS6<br>"
fi

## Check whether author and comment was specified.
if [ -n "$NOTIFICATIONCOMMENT" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>Comment: </strong>&nbsp;&nbsp;&nbsp;&nbsp;
<font color='#3333ff'>$NOTIFICATIONCOMMENT</font> by <font color='#c47609'>$NOTIFICATIONAUTHORNAME</font><br>"
fi

## Check whether Icinga Web 2 URL was specified.
if [ -n "$ICINGAWEB2URL" ] ; then

  SERVICENAME=${SERVICENAME// /%20}

  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE

<strong>Service:</strong> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href='$ICINGAWEB2URL/monitoring/service/show?host=$HOSTNAME&service=$SERVICENAME'>$SERVICENAME</a> <br>"

elif [ -z "$ICINGAWEB2URL" ] ; then

  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE

<strong>Service:</strong>&emsp;&ensp; $SERVICENAME<br>"

fi

## Additional Info
if [ -n "$SERVICEOUTPUT" ]; then
    NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
<strong>Info:</strong> &ensp; &emsp;&emsp;&emsp; <font color='$s_color'>$SERVICEOUTPUT</font><br>"
fi

while read line; do
  message="${message}\n${line}"
done <<< $NOTIFICATION_MESSAGE

BODY="${message}"

/usr/bin/printf "%b" "$NOTIFICATION_MESSAGE" | $CURLBIN -k -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d "{
\"msgtype\": \"m.text\",
\"body\": \"$BODY\",
\"formatted_body\": \"$BODY\",
\"format\": \"org.matrix.custom.html\"
      }" "$MATRIXSERVER/_matrix/client/r0/rooms/$MATRIXROOM/send/m.room.message/$MX_TXN?access_token=$MATRIXTOKEN"
