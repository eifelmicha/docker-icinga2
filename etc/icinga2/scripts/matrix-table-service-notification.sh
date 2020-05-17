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
    h) Usage ;;
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
       Usage ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Usage ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Usage ;;
  esac
done

shift $((OPTIND - 1))

## Keep formatting in sync with mail-host-notification.sh
for P in LONGDATETIME HOSTNAME HOSTDISPLAYNAME SERVICENAME SERVICEDISPLAYNAME SERVICEOUTPUT SERVICESTATE NOTIFICATIONTYPE ; do
        eval "PAR=\$${P}"

        if [ ! "$PAR" ] ; then
                Error "Required parameter '$P' is missing."
        fi
done

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

## Build the notification message
NOTIFICATION_MESSAGE=`cat << EOF
<table>
  <tr>
      <font color='$s_color'><strong> $ico Service Monitoring on $ICINGA2HOST </font></strong><br>
  </tr>
  <tr>
    <th colspan='2'>$NOTIFICATIONTYPE:</th>
    <td>$SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is <font color='$s_color'>$SERVICESTATE!</font></td>
  </tr>
  <tr>
    <th>When:</th>
    <td>$LONGDATETIME</td>
  </tr>
EOF
`

## Check whether IPv4 / IPv6 was specified.
if [ -n "$HOSTADDRESS" ] && [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Host:</th>
    <td>$HOSTNAME</td>
  </tr>
  <tr>
    <th>IPv4:</th>
    <td>$HOSTADDRESS</td>
  </tr>
  <tr>
    <th>IPv6:</th>
    <td>$HOSTADDRESS6</td>
  </tr>"
elif [ -n "$HOSTADDRESS" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Host:</th>
    <td>$HOSTNAME / $HOSTADDRESS</td>
  </tr>"
elif [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Host:</th>
    <td>$HOSTNAME / $HOSTADDRESS6</td>
  </tr>"
fi

## Check whether author and comment was specified.
if [ -n "$NOTIFICATIONCOMMENT" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Comment:</th>
    <td>
      <font color='#3333ff'>$NOTIFICATIONCOMMENT</font> by <font color='#c47609'>$NOTIFICATIONAUTHORNAME</font>
    </td>
  </tr>"
fi

## Additional Info
SERVICENAME=${SERVICENAME// /%20}
if [ -n "$ICINGAWEB2URL" ]; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Service:</th>
    <td><a href='$ICINGAWEB2URL/monitoring/service/show?host=$HOSTNAME&service=$SERVICENAME'>$SERVICENAME</a></td>
  </tr>"
else
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Service:</th>
    <td>$SERVICENAME</td>
  </tr>"
fi

if [ -n "$SERVICEOUTPUT" ]; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
  <tr>
    <th>Info:</th>
    <td><font color='$s_color'>$SERVICEOUTPUT</font></td>
  </tr>"
fi

## Check whether Icinga Web 2 URL was specified.
# if [ -n "$ICINGAWEB2URL" ] ; then
#   # Replace space with HTML
#   SERVICENAME=${SERVICENAME// /%20}
#   NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE $ICINGAWEB2URL/monitoring/service/show?host=$HOSTNAME&service=$SERVICENAME <br/>"
# fi

# close table
NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
</table>"

while read line; do
  message="${message}\t${line}"
done <<< $NOTIFICATION_MESSAGE

BODY="${message}"

/usr/bin/printf "%b" "$NOTIFICATION_MESSAGE" | $CURLBIN -k -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d "{
\"msgtype\": \"m.text\",
\"body\": \"$BODY\",
\"formatted_body\": \"$BODY\",
\"format\": \"org.matrix.custom.html\"
      }" "$MATRIXSERVER/_matrix/client/r0/rooms/$MATRIXROOM/send/m.room.message/$MX_TXN?access_token=$MATRIXTOKEN"
