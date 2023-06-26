#!/bin/bash
echo "masterip :" `cat /etc/masterip`
echo "slaveip  :" `cat /etc/slaveip`
echo "sshport  :" `cat /etc/sshport`
#masterip=`cat /etc/masterip`
echo "Verify masterIP ,slaveIP and slave sshport , confirm with yes/no:"
read inp
  case $inp in
    "yes")
      slaveip=`cat /etc/slaveip`
      sshport=`cat /etc/sshport`
      masterip=`cat /etc/masterip`;;
    "no")
      echo "Please update correct ip in /etc/slaveip and /etc/masterip, slave ssh port in /etc/sshport"
      exit;; 
     *)
      echo "Ooops wrong entry"
      exit;;
  esac
#echo "slave ip is" $slaveip
A=`echo $slaveip | awk '/^([0-9]{1,3}[.]){3}([0-9]{1,3})$/{print $1}'`
if [ -z $A ]; then
   red='\033[0;31m'
   # Clear the color after that
   clear='\033[0m'
   printf "${red}Please input a valid IP address${clear} \n "
   exit
else
  green='\033[0;32m'
  # Clear the color after that
  clear='\033[0m'
  printf "${green}Server Reset started${clear}! \n"
fi
echo "The master server IP is:" $masterip
echo "The slave server IP is :" $slaveip
timeout 5s ssh -p $sshport -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi

if [[ $(rpm -qa | grep -i mysql-community-server) == *mysql-community-server-8* ]]; then
   echo "Mysql removing in master server:"
   systemctl stop mysqld
   mv /etc/my.cnf /etc/my.cnf_`date +"%d-%m-%Y-%s"`
   mv /var/lib/mysql /var/lib/mysql_`date +"%d-%m-%Y-%s"`
   timeout 240s dnf remove mysql-community-server -y >> /tmp/server_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql uninstallation failed, please check issue"
   exit
else
echo "OK"
fi
else
echo "Mysql not installed in master server"
fi
echo "Removing  mysql repo in master server:"
if [[ $(rpm -qa | grep -i mysql80-community-release-el8-5.noarch) == mysql80-community-release-el8-5.noarch ]]; then
   timeout 120s yum remove mysql80-community-release-el8* -y  >> /tmp/server_reset.log 2>&1
fi
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql repo uninstallation failed, please check issue"
else
echo "OK"
fi
echo " Slave Server Reset started:"
ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip "uptime" >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root passwordless ssh connectivity to slave server failed"
   exit
else
echo "===================================slave server logs started=============" >> /tmp/replication_reset.log
#ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  /tmp/replication_server_reset.sh
ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  "bash <(curl -sL https://raw.githubusercontent.com/vimoshmohan/mysqllab/main/slave_scripts/replication_slave_server_reset_el8.sh)"
if [[ $(echo $?) -gt 0 ]]; then
   echo "Please check issue in slave server"
   exit
else
echo "Server reset has been completed Successfully"
