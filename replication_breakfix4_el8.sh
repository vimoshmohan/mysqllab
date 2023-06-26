#!/bin/bash
slaveip=`cat /etc/slaveip`
masterip=`cat /etc/masterip`
sshport=`cat /etc/sshport`
echo "The master server IP address is:" $masterip
echo "The slave server IP address is:" $slaveip
timeout 5s ssh -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi
#ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  "/tmp/replication_brkfix4_slave_el8.sh"
ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  "bash <(curl -sL https://raw.githubusercontent.com/vimoshmohan/mysqllab/main/slave_scripts/replication_brkfix4_slave_el8.sh)"
   

