#!/bin/bash
#----------主备节点配置文件对比脚本----------
#以下代表Nagios报警级别 0=OK 1=WARNING 2=CRITICAL 3=UNKNOWN 
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
#对端主机
peer_user="root"
peer_ip="172.16.8.9"
#配置文件目录
check_dir=("/sumapay/config" "/sumapay/exception" "/sumapay/schedual/config" "/sumapayex/config")
#结果文件目录
dir="/usr/local/nagios/libexec/check_data/"
tmp_list="/usr/local/nagios/libexec/check_data/tmp_list.txt"
source_list="/usr/local/nagios/libexec/check_data/source_list.txt"
short_list="/usr/local/nagios/libexec/check_data/short_list.txt"
source_md5="/usr/local/nagios/libexec/check_data/source_md5.txt"
dest_md5="/usr/local/nagios/libexec/check_data/dest_md5.txt"
compare_result="/usr/local/nagios/libexec/check_data/compare_result.txt"
#创建目录
if [ ! -d $dir ];then
        mkdir $dir
fi
#清除历史记录
echo > $short_list
echo > $source_md5
echo > $dest_md5
echo > $compare_result
#目录文件检查并输出结果文件
for i in ${check_dir[@]};do
	ssh $peer_user@$peer_ip "ls -l $i" > $tmp_list
	grep ^'-' $tmp_list|awk '{print $NF}' > $source_list
	for n in `cat $source_list`;do
		file_name="$i/$n"
		if [ ! -f $file_name ];then
			echo "$file_name" >> $short_list
			sed -i 's/$n//' $source_list
		else
			ssh $peer_user@$peer_ip "md5sum $file_name" >> $source_md5
			md5sum $file_name >> $dest_md5
		fi
	done
	diff $source_md5 $dest_md5 >> $compare_result
done
#检查结果文件
sed -i '/^\s*$/d' $short_list
sed -i '/^\s*$/d' $compare_result
SHORT=`cat $short_list`
COMP=`cat $compare_result|grep ^'<'|awk '{print $3}'`
if [ -s $short_list ];then
	echo "some files are short！They are：$SHORT"
		if [ -s $compare_result ];then
			echo "some files MD5 are diff! They are: $COMP"
			exit $STATE_CRITICAL
		else
			echo "files MD5 are OK!"
			exit $STATE_WARNING
		fi
else
	echo "files num is OK!"
		if [ -s $compare_result ];then
			echo "some files MD5 are diff! They are: $COMP"
			exit $STATE_WARNING
		else
			echo "files MD5 is OK!"
			exit $STATE_OK
		fi
fi

