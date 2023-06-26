#!/bin/bash
slaveip=`cat /etc/slaveip`
masterip=`cat /etc/masterip`
sshport=`cat /etc/sshport`
echo "The master server IP address is:" $masterip
echo "The slave server IP address is :" $slaveip
timeout 5s ssh -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi
mysql -e "ALTER USER 'replicant'@'$slaveip' IDENTIFIED BY '#Q5fdjYUF1XFSi911';flush privileges;"
   if [[ $(echo $?) -gt 0 ]]; then
   echo "Breakfix2 execution failed, please investigate issue"
   else
   ssh -p $sshport -o StrictHostKeyChecking=no $slaveip  "mysql --defaults-extra-file=/root/.my.cnf -e 'stop slave;start slave'"
   echo "Breakfix2 executed successfully,please try to fix the replication issue and execute replication status script once issue fixed"
   fi
