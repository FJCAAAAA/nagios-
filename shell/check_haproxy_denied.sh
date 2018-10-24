#!/bin/bash
export LANG=en_US.UTF-8

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
echo "show stat" | socat /var/lib/haproxy/stats stdio |sed '/^[[:space:]]*$/d' | grep -v "stat" > /tmp/haproxy_denied_gather
awk -F ',' '{print $11,$12}' /tmp/haproxy_denied_gather > /tmp/check_haproxy_denied.txt
grep '[1-9]' /tmp/check_haproxy_denied.txt
if [ $? = 0 ]; then
echo "Haproxy has rejected the connection!"
exit $STATE_CRITICAL;
else
echo "OK"
exit $STATE_OK;
fi
