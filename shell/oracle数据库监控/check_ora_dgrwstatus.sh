#!/bin/bash
# 监控DG集群中各数据库的读写状态
# 通过sys用户查询：select open_mode from v$database;


#环境变量
#source /home/oracle/.bash_profile
source /etc/profile
export NLS_LANG="AMERICAN_AMERICA.UTF8"
export LANG=en_US.UTF-8
#
namehead="check_ora_dgrwstatus"

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
print_help() {
echo "Usage:"
    echo "  -H)"
    echo "    主机地址"
	echo "mdb:RW  bdb2:RO"
#echo "[-w] Warning level as a percentage w%"
#echo "[-c] Critical level as a percentage c%"
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
RO|-RO)
RWRO=READONLYWITHAPPLY
RWRO1=READONLY
shift
;;
RW|-RW)
RWRO=READWRITE
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
if [ "$RWRO" == "" ]; then
echo "No mdb:RW  bdb2:RO Specified"
print_help
exit  $STATE_UNKNOWN;
fi
if [ "$HOSTADDRESS" == "" ]; then
echo "No HOSTADDRESS Specified"
print_help
exit  $STATE_UNKNOWN;
fi
datadir=/usr/local/nagios/libexec/datacheck
SQLFILE=${datadir}/${namehead}_${HOSTADDRESS}.sql
OUTFILE=${datadir}/${namehead}_${HOSTADDRESS}.txt
echo -n '
select open_mode from v$database;
' > $SQLFILE

SQLFILEa=${datadir}/${namehead}_a.sql
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

sed -i '/---/d' $OUTFILE
sed -i 's/\ //g' $OUTFILE
sed -i '/^$/d' $OUTFILE

RWstatus=`sed -n '/OPEN_MODE/{n;p}' $OUTFILE | cut -d ',' -f1`

result=$RWstatus

#rm -f $OUTFILE
#rm -f $SQLFILE
echo "" > $OUTFILE
echo "" > $SQLFILE

if [ -z "$result" ] ;then
echo "RWRO UNKNOWN. RWstatus is $RWstatus"
exit  $STATE_UNKNOWN
elif [ "$result"x == "$RWRO"x ] || [ "$result"x == "$RWRO1"x ]; then
echo "RWRO OK. RWstatus is $RWstatus|RWRO=1;$warn_level;$critical_level;0"
exit  $STATE_OK;
else 
echo "RWRO CRITICAL. RWstatus is $RWstatus|RWRO=0;$warn_level;$critical_level;0"
exit  $STATE_CRITICAL;
fi
