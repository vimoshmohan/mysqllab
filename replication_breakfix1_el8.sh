#!/bin/bash
slaveip=`cat /etc/slaveip`
masterip=`cat /etc/masterip`
sshport=`cat /etc/sshport`
echo "The master server IP address is:" $masterip
echo "The slave server IP address is:" $slaveip
echo "The slave sshport is:" $sshport
timeout 5s ssh -p $sshport -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi
mysql -e "revoke replication slave  on *.* from 'replicant'@'$slaveip';flush privileges;"
   if [[ $(echo $?) -gt 0 ]]; then
   echo "Breakfix1 execution failed, please investigate issue"
   else
   ssh -p $sshport -o StrictHostKeyChecking=no $slaveip  "mysql --defaults-extra-file=/root/.my.cnf -e 'stop slave;start slave'"
   echo "Breakfix1 executed successfully,please try to fix the replication issue and execute replication status script once issue fixed"
   fi
