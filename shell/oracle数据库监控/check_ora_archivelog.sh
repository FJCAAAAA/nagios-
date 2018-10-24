#!/bin/bash
#检查oracle归档日志使用空间
#通过sys用户查询：select PERCENT_SPACE_USED from v$flash_recovery_area_usage where FILE_TYPE='ARCHIVED LOG';

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
SQLFILE=${datadir}/check_ora_archivelog.sql
OUTFILE=${datadir}/check_ora_archivelog.txt
echo -n "
select PERCENT_SPACE_USED from v\$flash_recovery_area_usage where FILE_TYPE='ARCHIVED LOG';
" > $SQLFILE

SQLFILEa=${datadir}/check_ora_archivelog_a.sql
echo -n "
conn sys/password@$HOSTADDRESS/tvpay as sysdba
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

sed -i 's/\ //g' $OUTFILE
archivelogspace=`cat $OUTFILE|tail -2|head -1`
result=`echo $archivelogspace|cut -d . -f1`
rm -f $OUTFILE
rm -f $SQLFILE
if [ -z $result ]; then
echo "archivelogspace OK. $archivelogspace% used |archivelogspace=$archivelogspace%;$warn_level;$critical_level;0"
exit  $STATE_OK;
elif [ "$result" -le "$warn_level" ]; then
echo "archivelogspace OK. $archivelogspace% used |archivelogspace=$archivelogspace%;$warn_level;$critical_level;0"
exit  $STATE_OK;
elif [ "$result" -gt "$warn_level" ] && [ "$result" -lt "$critical_level" ]; then
echo "archivelogspace WARNING. $archivelogspace% used |archivelogspace=$archivelogspace%;$warn_level;$critical_level;0"
exit  $STATE_WARNING;
elif [ "$result" -ge "$critical_level" ]; then
echo "archivelogspace CRITICAL. $archivelogspace% used |archivelogspace=$archivelogspace%;$warn_level;$critical_level;0"
exit  $STATE_CRITICAL;
fi
