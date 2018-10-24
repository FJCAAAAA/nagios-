#!/bin/bash
#检查数据库asm磁盘使用情况

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
echo "[-d] DISK like FRA;DATA;CRS"
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
-d)
disk=$2
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
SQLFILE=${datadir}/check_ora_rac_asm_${HOSTADDRESS}_${disk}.sql
OUTFILE=${datadir}/check_ora_rac_asm_${HOSTADDRESS}_${disk}.txt
echo -n "
select b.name, a.useage from (select t.GROUP_NUMBER,
       to_char(round((sum(t.TOTAL_MB) - sum(t.FREE_MB)) / sum(t.TOTAL_MB) * 100,
                     2),
               '99.99') as useage
  from v\$asm_disk t
 group by t.group_number) a ,v\$asm_diskgroup b
 where a.GROUP_NUMBER = b.GROUP_NUMBER;
" > $SQLFILE

SQLFILEa=${datadir}/check_ora_rac_asm_a_$HOSTADDRESS.sql
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
asm_disk=`cat $OUTFILE|grep ${disk}`
#result=`echo $asm_disk|awk -F ',' '{print $2}' |sed 's/%//g'`
result=`echo $asm_disk|awk -F ',' '{print $2}'|cut -d . -f1`

#rm -f $OUTFILE
#rm -f $SQLFILE
echo "" > $OUTFILE
echo "" > $SQLFILE

if [ -z $result ]; then
echo "$disk UNKNOWN. $result% used |$disk=$result%;$warn_level;$critical_level;0"
exit  $STATE_UNKNOWN;
elif [[ "$result" -le "$warn_level" ]]; then
echo "asm disk $disk OK. $result% used |$disk=$result%;$warn_level;$critical_level;0"
exit  $STATE_OK;
elif [[ "$result" -gt "$warn_level" ]] && [[ "$result" -lt "$critical_level" ]]; then
echo "asm disk $disk WARNING. $result% used |$disk=$result%;$warn_level;$critical_level;0"
exit  $STATE_WARNING;
elif [[ "$result" -ge "$critical_level" ]]; then
echo "asm disk $disk CRITICAL. $result% used |$disk=$result%;$warn_level;$critical_level;0"
exit  $STATE_CRITICAL;
fi
