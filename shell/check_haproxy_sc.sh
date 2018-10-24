#!/bin/bash
export LANG=en_US.UTF-8

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
echo "show stat" | socat /var/lib/haproxy/stats stdio |sed '/^[[:space:]]*$/d' | grep -v "stat" > /tmp/haproxy_sc_gather
awk -F ',' '{if($5 >= 0 && $5 <= $7*0.5){print 0} else {print 2}}' /tmp/haproxy_sc_gather |uniq > /tmp/check_haproxy_sc.txt
cat /tmp/check_haproxy_sc.txt|grep 2
if [ $? == 0 ]; then
echo "The session number is too much"
exit $STATE_CRITICAL;
else
echo "OK"
exit $STATE_OK;
fi
