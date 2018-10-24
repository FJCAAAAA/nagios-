#!/bin/bash
#检查系统中CPU使用率最高的前五位进程
STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
print_help() {
echo "Usage:"
echo ""
echo ""
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

Commandfile=/usr/local/nagios/libexec/datacheck/cpu_usage_of_command.txt
#统计cpu占用率前五的进程
ps aux|sed '1d'|sort -r -k3|head -n 5 > $Commandfile
#Command=`cat $Commandfile|awk '{for (i=1;i<=10;i++)$i="";print $0}'`
#统计这五个进程对应的cpu占用率
#Usage=`cat $Commandfile|awk '{print $3}'`
#统计单个进程cpu最大占用率
maxUsage=`cat $Commandfile|awk '{print $3}'|head -n 1`
if [ `echo "${maxUsage} < ${warn_level}"|bc` -eq 1 ];then
	echo -e "Single process CPU utilization is fine.The processes are:\n`cat $Commandfile|awk '{for (i=1;i<=10;i++)$i="";print $0}'` \nThe Usages are:\n`cat $Commandfile|awk '{print $3}'`"
	echo "" > $Commandfile
	exit $STATE_OK
elif [ `echo "$maxUsage > $warn_level"|bc` -eq 1 ];then
	echo -e "Single process CPU utilization is fine.The processes are:\n`cat $Commandfile|awk '{for (i=1;i<=10;i++)$i="";print $0}'` \nThe Usages are:\n`cat $Commandfile|awk '{print $3}'`"
	echo "" > $Commandfile
	exit $STATE_WARNING
elif [ `echo "$maxUsage > $critical_level"|bc` -eq 1 ];then
	echo -e "Single process CPU utilization is fine.The processes are:\n`cat $Commandfile|awk '{for (i=1;i<=10;i++)$i="";print $0}'` \nThe Usages are:\n`cat $Commandfile|awk '{print $3}'`"
	echo "" > $Commandfile
	exit $STATE_CRITICAL
fi

