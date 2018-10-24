#!/bin/bash
export LANG=en_US.UTF-8

STATE_OK=0 
STATE_WARNING=1 
STATE_CRITICAL=2 
STATE_UNKNOWN=3
echo "show stat" | socat /var/lib/haproxy/stats stdio |sed '/^[[:space:]]*$/d' | grep -v "stat" > /tmp/haproxy_warings_gather
awk -F ',' '{print $13,$14,$15}' /tmp/haproxy_warings_gather > /tmp/check_haproxy_warings.txt
grep '[1-9]' /tmp/check_haproxy_warings.txt
if [ $? = 0 ]; then
echo "Haproxy have warings connection!"
exit $STATE_CRITICAL;
else
echo "OK"
exit $STATE_OK;
fi
 
