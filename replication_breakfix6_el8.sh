#!/bin/bash
slaveip=`cat /etc/slaveip`
masterip=`cat /etc/masterip`
sshport=`cat /etc/sshport`
echo "The master server IP address is:" $masterip
echo "The slave server IP address is:" $slaveip
echo " The slave sshport is:" $sshport
timeout 5s ssh -p $sshport -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi
sed -i '/server-id/ i port=3360' /etc/my.cnf
systemctl restart mysqld
if [[ $(echo $?) -gt 0 ]]; then
   echo "Breakfix6 failed please investigate issue"
else
  ssh -p $sshport  -o StrictHostKeyChecking=no $slaveip  "mysql --defaults-extra-file=/root/.my.cnf -e 'stop slave;start slave;'"
  if [[ $(echo $?) -gt 0 ]]; then
  echo "Breakfix6 failed please investigate issue"
  else
  echo "Breakfix6 has been completed successfully, please check and fix replication issue"
  fi
  fi

