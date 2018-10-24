#!/bin/sh
#检查数据库当前进程的连接数
#通过sys用户查询：select count(*) from v$process;

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
echo "[-w] Warning level process_count"
echo "[-c] Critical level process_count"
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
SQLFILE=${datadir}/check_ora_rac_process.sh.sql
OUTFILE=${datadir}/check_ora_rac_process.sh.txt
echo -n "
select count(*) from v\$process;
" > $SQLFILE

SQLFILEa=${datadir}/check_ora_process.sh_a.sql
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
#rm -f $SQLFILEa

sed -i 's/[[:space:]]//g' $OUTFILE
sed -i '/---/d' $OUTFILE
process_count=`sed -n '3p' $OUTFILE`
#active_status_count=`sed -n '/ACTIVE_STATUS_COUNT/{n;p}' $OUTFILE`
#user_count=`sed -n '/USER_COUNT/{n;p}' $OUTFILE`

result=$process_count
rm -f $OUTFILE
rm -f $SQLFILE

if [[ "$result" -le "$warn_level" ]]; then
echo "process_count OK.process_count:$process_count |PROCESS_COUNT=$process_count;$warn_level;$critical_level;"
exit  $STATE_OK;
elif [[ "$result" -gt "$warn_level" ]] && [[ "$result" -lt "$critical_level" ]]; then
echo "process_count WARNING. process_count:$process_count |PROCESS_COUNT=$process_count;$warn_level;$critical_level;"
exit  $STATE_WARNING;
elif [[ "$result" -ge "$critical_level" ]]; then
echo "process_count CRITICAL. process_count:$process_count |PROCESS_COUNT=process_count;$warn_level;$critical_level;"
exit  $STATE_CRITICAL;
fi
