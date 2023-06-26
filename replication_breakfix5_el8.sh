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
db=`mysql -e "show databases like '%repdb%';" | grep -w repdb | grep -v Database`
#echo $db
if [[ $db == repdb ]] 
then
echo "Please execute replication_reset script in master server and then retry"
exit
else
#timeout 30s ssh -o StrictHostKeyChecking=no root@$slaveip "/tmp/replication_brkfix5_slave_rl8.sh" 
timeout 30s ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  "bash <(curl -sL https://raw.githubusercontent.com/vimoshmohan/mysqllab/main/slave_scripts/replication_brkfix5_slave_el8.sh)"
fi
mysql -e "create database repdb;"

