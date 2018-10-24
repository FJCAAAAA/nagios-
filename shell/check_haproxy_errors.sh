#!/bin/bash
export LANG=en_US.UTF-8

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
echo "show stat" | socat /var/lib/haproxy/stats stdio |sed '/^[[:space:]]*$/d' | grep -v "stat" > /tmp/haproxy_errors_gather
awk -F ',' '{print $13,$14,$15}' /tmp/haproxy_errors_gather > /tmp/check_haproxy_errors.txt
grep '[1-9]' /tmp/check_haproxy_errors.txt
if [ $? = 0 ]; then
echo "Haproxy incorrect connection!"
exit $STATE_CRITICAL;
else
echo "OK"
exit $STATE_OK;
fi
 
