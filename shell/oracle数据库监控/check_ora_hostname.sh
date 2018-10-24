#!/bin/bash
# 检查数据库的主机名
# 通过sys用户查询：select host_name from v$instance;

#环境变量
#source /home/oracle/.bash_profile
source /etc/profile
export NLS_LANG="AMERICAN_AMERICA.UTF8"
export LANG=en_US.UTF-8
#
namehead="check_ora_hostname"

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
print_help() {
echo "Usage:"
    echo "  -H 主机地址 -n 目标主机名 "
    echo "    "
	echo ""
#echo "[-w] Warning level as a percentage w%"
#echo "[-c] Critical level as a percentage c%"
exit  $STATE_UNKNOWN
}
while test -n "$1"; do
case "$1" in
--help|-h)
print_help
exit  $STATE_UNKNOWN
;;
	--url|-H) 
    HOSTADDRESS=$2 
    shift
    ;;
-n)
hostnameOB=$2
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
if [ "$hostnameOB" == "" ]; then
echo "No hostnameOB Specified"
print_help
exit  $STATE_UNKNOWN;
fi
if [ "$HOSTADDRESS" == "" ]; then
echo "No HOSTADDRESS Specified"
print_help
exit  $STATE_UNKNOWN;
fi
datadir=/usr/local/nagios/libexec/datacheck
SQLFILE=${datadir}/${namehead}.sql
OUTFILE=${datadir}/${namehead}.txt
echo -n '
select host_name from v$instance;
' > $SQLFILE

SQLFILEa=${datadir}/${namehead}_a.sql
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

sed -i '/---/d' $OUTFILE
sed -i 's/\ //g' $OUTFILE
sed -i '/^$/d' $OUTFILE

hostnameCU=`sed -n '/HOST_NAME/{n;p}' $OUTFILE | cut -d ',' -f1`

result=$hostnameCU

rm -f $OUTFILE
rm -f $SQLFILE

if [ "$result"x == "$hostnameOB"x ]; then
echo "DB hostnameOB OK. $HOSTADDRESS  hostname is $result"
exit  $STATE_OK;
else 
echo "DB hostnameOB CRITICAL. $HOSTADDRESS  hostname is $result"
exit  $STATE_CRITICAL;
fi
