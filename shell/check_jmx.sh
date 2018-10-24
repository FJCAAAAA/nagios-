#!/bin/sh
#glassfish的jvm性能监控

source /etc/profile
JAVA_CMD=`which java`

if [ -z $JAVA_CMD ]
then

  if [ -x $JAVA_HOME/bin/java ]
  then
    JAVA_CMD=$JAVA_HOME/bin/java
  else
    echo JMX CRITICAL - java not found.
    exit 2
  fi

fi

DIR=`dirname $0`
$JAVA_CMD -jar $DIR/check_jmx.jar "$@"


#不同jmx不用的参数参数
#MetaSpaceUsed
#-U service:jmx:rmi:///jndi/rmi://$HOSTADDRESS$:$ARG3$/jmxrmi -O 'java.lang:type=MemoryPool,name=Metaspace' -A Usage -K used --username $USER2$ --password $USER3$ -w $ARG1$ -c $ARG2$ 
#FGCtime
#-U service:jmx:rmi:///jndi/rmi://$HOSTADDRESS$:$ARG3$/jmxrmi -O 'java.lang:type=GarbageCollector,name=PS MarkSweep' -A LastGcInfo -K duration --username $USER2$ --password $USER3$ -w $ARG1$ -c $ARG2$
#Mem
#-U service:jmx:rmi:///jndi/rmi://$HOSTADDRESS$:$ARG3$/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -vvvv -w $ARG1$ -c $ARG2$ --username $USER2$ --password $USER3$
#OldGenUsed
#-U service:jmx:rmi:///jndi/rmi://$HOSTADDRESS$:$ARG3$/jmxrmi -O 'java.lang:type=MemoryPool,name=PS Old Gen' -A Usage -K used --username $USER2$ --password $USER3$ -w $ARG1$ -c $ARG2$
#ThreadCount
#-U service:jmx:rmi:///jndi/rmi://$HOSTADDRESS$:$ARG3$/jmxrmi -O java.lang:type=Threading -A ThreadCount --username $USER2$ --password $USER3$ -w $ARG1$ -c $ARG2$