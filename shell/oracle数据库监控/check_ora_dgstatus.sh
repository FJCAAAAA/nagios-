#!/bin/bash
# 监控DG集群中各数据库的主备状态
# 通过sys用户查询：select t.DATABASE_ROLE  from v$database t;

#环境变量
#source /home/oracle/.bash_profile
source /etc/profile
export NLS_LANG="AMERICAN_AMERICA.UTF8"
export LANG=en_US.UTF-8
#
namehead="check_ora_dgstatus"

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
print_help() {
echo "Usage:"
    echo "  -H)"
    echo "    主机地址"
	echo "rac&rman:PRIMARY  dg:STANDBY"
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
STANDBY|-STANDBY)
STATUS="PHYSICALSTANDBY"
shift
;;
PRIMARY|-PRIMARY)
STATUS=PRIMARY
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
if [ "$STATUS" == "" ]; then
echo "No rac&rman:PRIMARY  dg:STANDBY Specified"
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
select t.DATABASE_ROLE  from v$database t;
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

status=`sed -n '/DATABASE_ROLE/{n;p}' $OUTFILE | cut -d ',' -f1`

output=`cat $OUTFILE`
result=$status

#rm -f $OUTFILE
#rm -f $SQLFILE
echo "" > $OUTFILE
echo "" > $SQLFILE

if [ -z "$result" ] ;then
echo "STATUS UNKNOWN. status is $status."
exit  $STATE_UNKNOWN
elif [ "$result"x == "$STATUS"x ]; then
echo "DGstatus OK. DGstatus is $status|DGstatus=1;$warn_level;$critical_level;0"
exit  $STATE_OK;
else 
echo "DGstatus CRITICAL. DGstatus is $status. OUTPUT is $output|DGstatus=0;$warn_level;$critical_level;0"
exit  $STATE_CRITICAL;
fi
