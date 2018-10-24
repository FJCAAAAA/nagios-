#!/bin/sh
#检查服务器磁盘IO使用情况
STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
print_help() {
echo "Usage:"
echo "[-w] Warning level as a percentage w%"
echo "[-c] Critical level as a percentage c%"
exit  $STATE_OK
}
while test -n "$1"; do
case "$1" in
--help|-h)
print_help
exit  $STATE_OK
;;
-w)
warn_level=$2
shift
;;
-c)
critical_level=$2
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
if [ "$warn_level" == "" ]; then
echo "No Warning Level Specified"
print_help
exit  $STATE_UNKNOWN;
fi
if [ "$critical_level" == "" ]; then
echo "No Critical Level Specified"
print_help
exit  $STATE_UNKNOWN;
fi
iostatx=`iostat -kx 2 2|grep vda|tail -n1`


#每秒从设备读入的数据量,单位为K.
rkB=`echo $iostatx|awk '{print $6}'`
#每秒向设备写入的数据量,单位为K.
wkB=`echo $iostatx|awk '{print $7}'`
#在I/O请求发送到设备期间,占用CPU时间的百分比.用于显示设备的带宽利用率.当这个值接近100%时,表示设备带宽已经占满.
util=`echo $iostatx|awk '{print $14}'`
#每一个IO请求的处理的平均时间
await=`echo $iostatx|awk '{print $10}'`
#平均每次设备IO操作的服务时间
svctm=`echo $iostatx|awk '{print $13}'`
			
result=`echo $util | cut -d . -f1`
if [ "$result" -le "$warn_level" ]; then
echo "IO_util OK. $result% used |IO_util=$util%;$warn_level;$critical_level;0 read_sda_kB=$rkB write_sda_kB=$wkB await=$await svctm=$svctm"
exit  $STATE_OK;
elif [ "$result" -gt "$warn_level" ] && [ "$result" -lt "$critical_level" ]; then
echo "IO_util WARNING. $result% used |IO_util=$util%;$warn_level;$critical_level;0 read_sda_kB=$rkB write_sda_kB=$wkB await=$await svctm=$svctm"
exit  $STATE_WARNING;
elif [ "$result" -ge "$critical_level" ]; then
echo "IO_util CRITICAL. $result% used |IO_util=$util%;$warn_level;$critical_level;0 read_sda_kB=$rkB write_sda_kB=$wkB await=$await svctm=$svctm"
exit  $STATE_CRITICAL;
fi
