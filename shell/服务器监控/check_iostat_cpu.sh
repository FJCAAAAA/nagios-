#!/bin/sh
#检查服务器CPU使用情况
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

iostatc=`iostat -c |sed '1,3d'|head -1`

user=`echo $iostatc|awk '{print $1}'`
nice=`echo $iostatc|awk '{print $2}'`
system=`echo $iostatc|awk '{print $3}'`
iowait=`echo $iostatc|awk '{print $4}'`
steal=`echo $iostatc|awk '{print $5}'`
idle=`echo $iostatc|awk '{print $6}'`

cpu_usage=`echo "100 - $idle" |bc -l`
idle1=`echo $idle | cut -d . -f1`		
result=`echo "100 - $idle1" |bc -l`

if [ "$result" -le "$warn_level" ]; then
echo "cpu_usage OK. $result% used |cpu_usage=$cpu_usage%;$warn_level;$critical_level;0 user=$user nice=$nice system=$system iowait=$iowait steal=$steal"
exit  $STATE_OK;
elif [ "$result" -gt "$warn_level" ] && [ "$result" -lt "$critical_level" ]; then
echo "cpu_usage WARNING. $result% used |cpu_usage=$cpu_usage%;$warn_level;$critical_level;0 user=$user nice=$nice system=$system iowait=$iowait steal=$steal"
exit  $STATE_WARNING;
elif [ "$result" -ge "$critical_level" ]; then
echo "cpu_usage CRITICAL. $result% used |cpu_usage=$cpu_usage%;$warn_level;$critical_level;0 user=$user nice=$nice system=$system iowait=$iowait steal=$steal"
exit  $STATE_CRITICAL;
fi
