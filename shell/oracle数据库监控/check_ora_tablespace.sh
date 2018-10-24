#!/bin/sh
#检查特定表空间使用情况

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
datadir=/usr/local/nagios/libexec/datacheck
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

SQLFILE=${datadir}/check_ora_tablespace_${HOSTADDRESS}.sql
OUTFILE=${datadir}/check_ora_tablespace_${HOSTADDRESS}.txt
echo -n "
SELECT 
       To_char(Round(( D.TOT_GROOTTE_MB - F.TOTAL_BYTES ) / D.MAX_TOT_GROOTTE_MB * 100, 2), '990.99')
       || '%'                           "使用比"
FROM   (SELECT TABLESPACE_NAME,
               Round(Sum(BYTES) / ( 1024 * 1024 ), 2) TOTAL_BYTES,
               Round(Max(BYTES) / ( 1024 * 1024 ), 2) MAX_BYTES
        FROM   SYS.DBA_FREE_SPACE
        GROUP  BY TABLESPACE_NAME) F,
       (SELECT DD.TABLESPACE_NAME,
               Round(Sum(DD.BYTES) / ( 1024 * 1024 ), 2) TOT_GROOTTE_MB,
               Round(Sum(DD.MAXBYTES) / ( 1024 * 1024 ), 2) MAX_TOT_GROOTTE_MB
        FROM   SYS.DBA_DATA_FILES DD
        GROUP  BY DD.TABLESPACE_NAME) D
WHERE  D.TABLESPACE_NAME = F.TABLESPACE_NAME
       AND Upper(F.TABLESPACE_NAME) = 'TS_TVPAY2'
ORDER  BY 1;
" >> $SQLFILE

SQLFILEa=${datadir}/check_ora_tablespace_a.sql
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

sed -i 's/\ //g' $OUTFILE
tablespace=`cat $OUTFILE|tail -2|head -1`
tablespace1=`echo $tablespace|cut -d , -f4|cut -d % -f1`
result=`echo $tablespace|cut -d , -f4|cut -d . -f1`

echo "" > $OUTFILE
echo "" > $SQLFILE

if [[ "$result" -lt "$warn_level" ]]; then
echo "tablespace OK. $tablespace1% used |tablespace=$tablespace1;$warn_level;$critical_level;0"
exit  $STATE_OK;
elif [[ "$result" -ge "$warn_level" ]] && [[ "$result" -lt "$critical_level" ]]; then
echo "tablespace WARNING. $tablespace1% used |tablespace=$tablespace1;$warn_level;$critical_level;0"
exit  $STATE_WARNING;
elif [[ "$result" -ge "$critical_level" ]]; then
echo "tablespace CRITICAL. $tablespace1% used |tablespace=$tablespace1;$warn_level;$critical_level;0"
exit  $STATE_CRITICAL;
fi
