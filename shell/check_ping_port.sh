#检查ping、端口通信状况
#!/bin/bash
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"

print_help() {
echo "Usage:"
echo "[-H] wanIP"
exit  $STATE_OK
}
while test -n "$1"; do
case "$1" in
--help|-h)
print_help
exit  $STATE_OK
;;
-H)
wanIP=$2
shift
;;
-P)
wanPORT=$2
shift
;;
*)
echo "Unknown Argument: $1"
print_help
exit  $STATE_UNKNOWN
;;
esac
shift
done
ping_result=`ping $wanIP -c 4|grep "packet loss"`
#检查丢包率
LOSS=`echo "$ping_result"|egrep -o "[0-9]{1,3}\%"`
#检查端口连通性
PORT_STATUS=`nc -z -w 5 $wanIP $wanPORT`
if [[ $LOSS != "0%" ]];then
	if [[ $PORT_STATUS =~ "succeeded" ]];then
		echo "ping NO OK,port OK,loss_pro=$LOSS,$PORT_STATUS |loss_pro=$LOSS port_status=1"
		exit $STATE_CRITICAL;
	else
		echo "ping NO OK,port NO OK,loss_pro=$LOSS,$PORT_STATUS |loss_pro=$LOSS port_status=0"
		exit $STATE_CRITICAL;
	fi
else
	if [[ $PORT_STATUS =~ "succeeded" ]];then
                echo "ping OK,port OK,loss_pro=$LOSS,$PORT_STATUS |loss_pro=$LOSS port_status=1"
                exit $STATE_OK;
        else
                echo "ping OK,port NO OK,loss_pro=$LOSS,$PORT_STATUS |loss_pro=$LOSS port_status=0"
                exit $STATE_CRITICAL;
        fi
fi
