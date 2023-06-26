#!/bin/bash
systemctl stop mysqld >> /tmp/replication_breakfix4.log 2>&1
status1=`echo $?`
sed -i 's/101/100/g' /etc/my.cnf >> /tmp/replication_breakfix4.log 2>&1
status2=`echo $?`
systemctl start mysqld  >> /tmp/replication_breakfix4.log 2>&1
status3=`echo $?`
if [[ $status1 -gt 0 ]] || [[ $status2 -gt 0 ]] || [[ $status3 -gt 0 ]]
   then
   echo "Breakfix4 execution failed, please investigate issue"
   exit
else
   echo "Breakfix4 executed successfully,please try to fix the replication issue and execute replication status script once issue fixed"
fi
