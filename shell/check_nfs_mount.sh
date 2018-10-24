#!/bin/bash
#监控NFS挂载情况
#以下代表Nagios报警级别 0=OK 1=WARNING 2=CRITICAL 3=UNKNOWN
STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3

print_help() {
echo "Usage:"
echo "[-s] filesystem"
echo "[-d] mount point"
exit  $STATE_OK
}

while test -n "$1"; do
case "$1" in
--help|-h)
print_help
exit  $STATE_OK
;;
-s)
source_path=$2
shift
;;
-d)
dest_path=$2
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

Mount=`df -hT|grep nfs4`
if [[ $? == 0 ]];then
	Source=`echo $Mount|awk '{print $1}'`
	Dest=`echo $Mount|awk '{print $7}'`
	if [[ $Source == $source_path && $Dest == $dest_path ]];then
		echo "NFS mount normal."
		exit $STATE_OK
	else
		echo "NFS mount directory is false!"
		exit $STATE_WARNING
	fi
else
	echo "NFS mount exception!Please check!"
	exit $STATE_CRITICAL

fi
