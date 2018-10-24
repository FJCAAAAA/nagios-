#!/bin/sh
#检查数据库是否锁表

#环境变量
#source /home/oracle/.bash_profile
source /etc/profile
export NLS_LANG="AMERICAN_AMERICA.UTF8"
export LANG=en_US.UTF-8
#
STATE_OK=0 
STATE_WARNING=1
STATE_CRITICAL=2 
STATE_UNKNOWN=3
print_help() {
echo "Usage:"
    echo "  -H)"
    echo "    主机地址"
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
        --url|-H) 
    HOSTADDRESS=$2 
    shift
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

if [ "$HOSTADDRESS" == "" ]; then
echo "No HOSTADDRESS Specified"
print_help
exit  $STATE_UNKNOWN;
fi
datadir=/usr/local/nagios/libexec/datacheck
SQLFILE=${datadir}/check_ora_sidlock.sql
OUTFILE=${datadir}/check_ora_sidlock.txt

echo -n "
select c.sid,c.prev_exec_start,c.machine,b.object_name,b.owner,c.status,c.serial#
from gv\$locked_object a,dba_objects b,gv\$session c 
where   a.session_id = c.sid and b.object_id = a.object_id and a.INST_ID = c.INST_ID  and b.object_name not in
       ('ACCOUNT_FROZEN_SUM_HISTORY', 'TEMP_ACCOUNT_BALANCE', 'HIS_TURN_RECORD') order by c.prev_exec_start asc;
" > $SQLFILE
SQLFILEa=${datadir}/check_ora_sidlock_a.sql
echo -n "
conn sys/password@$HOSTADDRESS/sumapay as sysdba
set numwidth 50
set colsep ','
set newp none
set trimspool on
set echo off
set pagesize 1000
set head on
set term off
set feedback off
set termout off
set linesize 10000
set feedback off
alter session set nls_date_format='YYYY-MM-DD_HH24:MI:SS'; 
spool $OUTFILE
@$SQLFILE
spool off
" > $SQLFILEa
sqlplus /nolog < $SQLFILEa >/dev/null
rm -f $SQLFILEa

sed -i 's/[[:space:]]//g' $OUTFILE
sed -i '/SQL/d' $OUTFILE
sed -i '/---/d' $OUTFILE
sed -i '/^$/d' $OUTFILE
sed -i '1d' $OUTFILE
#排除TRADE_REQUEST_RECORD和ACCOUNT_CONTROL
sed -i '/ACCOUNT_CONTROL/d' $OUTFILE
sed -i '/TRADE_REQUEST_RECORD/d' $OUTFILE

sed -i 's/_/\ /g' $OUTFILE
if [ ! -s $OUTFILE ]; then
        echo "oracle sid lock OK. no tables locked.|prevtime=0;$warn_level;$critical_level;0."
        exit  $STATE_OK;
fi
        prevstarttime=`cat /usr/local/nagios/libexec/datacheck/check_ora_sidlock.txt | head -n 1|awk -F ',' '{print $2}'`
        prevremain=$(($(date +%s) - $(date +%s -d "$prevstarttime")))
        prevremainmin=`echo "$prevremain / 60"|bc -l|cut -d . -f1`
        result=$prevremainmin

	outfile=`cat /usr/local/nagios/libexec/datacheck/check_ora_sidlock.txt`

rm -f $SQLFILE
if [ -z $result ]; then
	echo "oracle lock OK. prev start time:0|prevtime=0;$warn_level;$critical_level;0."
	exit  $STATE_OK;
elif [ "$result" -le "$warn_level" ]; then
	echook="oracle lock OK. prev start time:$result $outfile|prevtime=$result;$warn_level;$critical_level;0."
	#exit  $STATE_OK;
	continue;
elif [ "$result" -gt "$warn_level" ] && [ "$result" -lt "$critical_level" ]; then
	echo -e "oracle lock WARNING.prev start time:$result $line $outfile|prevtime=$result;$warn_level;$critical_level;0."
	exit  $STATE_WARNING;
elif [ "$result" -ge "$critical_level" ]; then
	echo -e "oracle lock CRITICAL.prev start time:$result $line $outfile|prevtime=$result;$warn_level;$critical_level;0."
	exit  $STATE_CRITICAL;
fi
#done < $OUTFILE
rm -f $OUTFILE
echo $echook
exit  $STATE_OK;
