#!/bin/bash
export LANG=en_US.UTF-8

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
echo "show stat" | socat /var/lib/haproxy/stats stdio |sed '/^[[:space:]]*$/d' | grep -v "stat" > /tmp/haproxy_flow_gather
awk -F ',' '{if($9 >= 5242880 -o $10 >= 5242880){print 2} else {print 0}}' /tmp/haproxy_flow_gather |uniq > /tmp/check_haproxy_flow.txt
cat /tmp/check_haproxy_flow.txt|grep 2
if [ $? == 0 ]; then
echo "Haproxy traffic has been more than 5 M!"
exit $STATE_CRITICAL;
else
echo "OK"
exit $STATE_OK;
fi