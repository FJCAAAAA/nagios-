#!/bin/bash
#检查dg备库同步情况;用dg库scn值与主库scn值进行比对,差值超过20分钟报警
#通过sys用户查询：select current_scn from v$database; 

source /etc/profile
export NLS_LANG="AMERICAN_AMERICA.UTF8"
export LANG=en_US.UTF-8

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
datadir=/usr/local/nagios/libexec/datacheck

print_help() { 
    echo "  -H)"
    echo "    主机地址"
    echo "  -w|--warning "
    echo "  -c|--critical"
    exit $STATE_UNKNOWN 
} 

while test -n "$1"; do
case "$1" in
    --help|-h) 
    print_help 
    exit $STATE_UNKNOWN 
    ;; 
	--url|-H) 
    HOSTADDRESS=$2 
    shift
    ;;
    --warning|-w)
    WARNING=$2
    shift
    ;;
    --critical|-c)
    CRITICAL=$2
    shift
    ;;
        *) 
    echo "Unknown argument: $1"
    print_help 
    exit $STATE_UNKNOWN 
    ;; 
  esac
  shift
done

if [[ "$HOSTADDRESS" == "" || "$WARNING" == "" || "CRITICAL" == "" ]]; then
print_help
exit  $STATE_UNKNOWN;
fi

OUTFILE1=${datadir}/check_dg_scn.out
OUTFILE2=${datadir}/check_rac_scn.out
SQLFILEa=${datadir}/check_dg_scn_a.sql

function SelectSCN () {
echo -n "
conn sys/password@$DB:1521/sumapay as sysdba
spool $OUTFILE
select current_scn from v\$database; 
spool off
" > $SQLFILEa
sqlplus /nolog < $SQLFILEa >/dev/null
}

function FormatData ()
	{
	sed -i '/SQL/d' $OUTFILE
	sed -i '/^$/d' $OUTFILE
	sed -i 's/\ \ //g' $OUTFILE
	sed -i '/---/d' $OUTFILE
	sed -i '1d' $OUTFILE
}

#HOSTADDRESS=172.16.219.101
DB=$HOSTADDRESS
OUTFILE=$OUTFILE1
SelectSCN
FormatData
dgvalue=`cat $OUTFILE`


DB=172.16.219.99
OUTFILE=$OUTFILE2
SelectSCN
FormatData
racvalue=`cat $OUTFILE`

#value=`expr $racvalue - $dgvalue`
value=`expr $dgvalue - $racvalue`

#取value绝对值

if [ $value -lt 0 ]; then
  let value=0-$value;
fi

if [[ $value -ge $CRITICAL ]]; then
        echo "$HOSTADRESS scn value is CRITICAL,please check | value=$value;$WARNING;$CRITICAL"
        exit $STATE_CRITICAL;
else if [[ $value -ge $WARNING ]]; then
        echo "$HOSTADRESS scn vlaue is WARNING,please check | value=$value;$WARNING;$CRITICAL"
        exit $STATE_WARNING;
else
        echo "$HOSTADDRESS scn value is OK | value=$value;$WARNING;$CRITICAL"
        exit $STATE_OK;
        fi
fi





