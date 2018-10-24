#!/bin/bash
#检查cronsun计划任务执行情况
#以下代表Nagios报警级别 0=OK 1=WARNING 2=CRITICAL 3=UNKNOWN 
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
num_file=/usr/local/nagios/libexec/data/cronsun_failenum.txt

sql="db.stat.find({'date':'`date +"%Y-%m-%d"`'},{'failed':1});"
failed_num=`echo "$sql"|/usr/bin/mongo 172.16.1.22:27017/cronsun --shell|grep "failed"|awk '{print $7}'`

if [[ $failed_num > 0 ]];then
	if [[ $failed_num > `cat $num_file` ]];then
		echo "the number of failed tasks has increased! | Failed_Num=$failed_num"
		echo $failed_num > $num_file
		exit $STATE_CRITICAL
	else
		echo "cronsun has failed tasks! | Failed_Num=$failed_num"
		echo $failed_num > $num_file
		exit $STATE_WARNING
	fi
else
	echo "All tasks execute successfully! | Failed_Num=0"
	echo 0 > $num_file
	exit $STATE_OK
fi
