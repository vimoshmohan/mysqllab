#!/bin/bash
slaveip=`cat /etc/slaveip`
masterip=`cat /etc/masterip`
sshport=`cat /etc/sshport`
echo "The master server IP address is:" $masterip
echo "The slave server IP address is:" $slaveip
echo "The slave ssh port is :" $sshport
timeout 5s ssh -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi
firewall-cmd --remove-rich-rule='rule family=ipv4 source address="'$slaveip'" port port="3306" protocol=tcp accept' --permanent >> /tmp/replication_breakfix3.log 2>&1
   #status1=`echo $?`
   echo "status1" $status1
   firewall-cmd --reload >> /tmp/replication_breakfix3.log 2>&1
   #status2=`echo $?`
   echo "status2" $status2
   if [[ $status1 -gt 0 ]] || [[ $status2 -gt 0 ]]
   then
   echo "Breakfix3 execution failed, please investigate issue"
   exit
else
   ssh -p $sshport -o StrictHostKeyChecking=no $slaveip  "mysql --defaults-extra-file=/root/.my.cnf -e 'stop slave;start slave'" >> /tmp/replication_breakfix3.log 2>&1
   echo "Breakfix3 executed successfully,please try to fix the replication issue and execute replication status script once issue fixed"
fi
