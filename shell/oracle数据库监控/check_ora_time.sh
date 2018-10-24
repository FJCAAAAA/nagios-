#!/bin/sh
#检查数据库时间与系统时间对比情况
#查询命令：select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') from dual;
#环境变量
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
echo "[-w] Warning"
echo "[-c] Critical"
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
if [ "$HOSTADDRESS" == "" ]; then
echo "No HOSTADDRESS Specified"
print_help
exit  $STATE_UNKNOWN;
fi
datadir=/usr/local/nagios/libexec/datacheck
SQLFILE=${datadir}/check_ora_date.sh.${HOSTADDRESS}.sql
OUTFILE=${datadir}/check_ora_date.sh.${HOSTADDRESS}.txt
echo -n "
select to_char(sysdate,'yyyy-mm-dd/hh24:mi:ss') from dual;
" > $SQLFILE

SQLFILEa=${datadir}/check_ora_date.sh_a.sql
echo -n "
conn tvpay2/tvpay@$HOSTADDRESS/sumapay
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
sed -i '/---/d' $OUTFILE
sed -i '/SQL/d' $OUTFILE
sed -i '/CHAR/d' $OUTFILE
sed -i 's/\// /' $OUTFILE

ora_time1=`cat $OUTFILE`
ora_time=`date -d "$ora_time1" +%s`
cur_time=`date +%s` 

value=`expr $cur_time - $ora_time`

if [ $value -lt 0 ]; then
  let value=0-$value;
fi


if [[ "$value" -le "$warn_level" ]]; then
echo "oracle time is OK. ora_time-cur_time:$value|value=$value;$warn_level;$critical_level;0"
exit  $STATE_OK;
elif [[ "$value" -gt "$warn_level" ]] && [[ "$value" -lt "$critical_level" ]]; then
echo "oracle time is WARNING. ora_time-cur_time:$value|value=$value;$warn_level;$critical_level;0"
exit  $STATE_WARNING;
elif [[ "$value" -ge "$critical_level" ]]; then
echo "oracle time is CRITICAL. ora_time-cur_time:$value|value=$value;$warn_level;$critical_level;0"
exit  $STATE_CRITICAL;
fi
