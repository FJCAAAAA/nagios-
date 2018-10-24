#!/bin/bash
# 
# Description   : Nagios plugin (script) to check rabbitmq count.
# USAGE         : /opt/nagios/libexec/check_smsx_http_node.sh -H hostaddresss -p port -m message -w WARNING -c CRITICAL
# USAGE explain :  rabbitmq消息数,如:deadmessage，repeatmessage
# Exemple:      :  sh check_rabbitmq_message -H 172.16.8.3 -m repeat -p 9494 -w 5 -c 10
#		           sh check_rabbitmq_message -H 172.16.8.3 -m dead -p 9494 -w 5 -c 10 
#
#以下代表Nagios报警级别 0=OK 1=WARNING 2=CRITICAL 3=UNKNOWN 测试时全改为0
STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2
STATE_UNKNOWN=3

print_help() { 
    echo "  -H)"
    echo "    主机地址"
    echo "	-p/--port)"
    echo "	  http端口"
    echo "  -m/--message)"
    echo "    接口的状态项,如:sumapay，main，TVAndroid，merchant"
	echo "  -w|--WARNING  -c|--CRITICAL"
	echo "    Message count to messagecount in WARNING status "
	echo "	-c, --CRITICAL=DOUBLE"
    echo "	  Message count to messagecount in CRITICAL status"
    exit $STATE_UNKNOWN 
} 
#分析日志
logfile=/sumapayex/log/deadmessage/deadmessage.log
log_analysis=`grep  "connectorName" $logfile|tail -n 5|egrep -o 'connectorName=[a-z]{1,20}'|tr '\n' ' '`


while test -n "$1"; do
case "$1" in
    -help|-h) 
    print_help 
    exit $STATE_UNKNOWN 
    ;; 
	--url|-H) 
    HOSTADDRESS=$2 
    shift
    ;;
    --message|-m) 
    message=$2 
    shift
    ;; 
    --port|-p)
    PORT=$2
    shift
    ;;
    --WARNING|-w) 
    WARNING=$2 
    shift
    ;; 
    --CRITICAL|-c) 
    CRITICAL=$2 
    shift
    ;; 
        *) 
    echo "Unknown argument: $1"
    print_help 
    exit $STATE_UNKNOWN 
    ;; 
  esac
  shift
done

LIBDIR="/usr/local/nagios/libexec"
DATADIR="$LIBDIR/datacheck"
CHECKURL="MessageServlet?METHOD=count"

getfile=$DATADIR/$HOSTADDRESS-$message
wget --tries=2 --timeout=2 --no-check-certificate -O $getfile http://$HOSTADDRESS:$PORT/${message}message/$message$CHECKURL
if [ ! -s $getfile ]; then
	echo "$node CRITICAL;wget timeout".
	version=0
	rm -f $getfile
	exit $STATE_CRITICAL
fi

messagecount=`cat $getfile`

rm -f $getfile

if [ "$messagecount" -le "$WARNING" ]; then
echo "$message message count is OK. ${message}messagecount=$messagecount |${message}messagecount=$messagecount;$WARNING;$CRITICAL"
exit  $STATE_OK;
elif [ "$messagecount" -gt "$WARNING" ] && [ "$messagecount" -lt "$CRITICAL" ]; then
echo "$message message count is warning. ${message}messagecount=$messagecount detail: $log_analysis |${message}messagecount=$messagecount;$WARNING;$CRITICAL"
exit  $STATE_WARNING;
elif [ "$messagecount" -ge "$CRITICAL" ]; then
echo "$message message count is critical. ${message}messagecount=$messagecount detail: $log_analysis |${message}messagecount=$messagecount;$WARNING;$CRITICAL"
exit  $STATE_CRITICAL;
fi
#end
