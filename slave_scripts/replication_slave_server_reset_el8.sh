#!/bin/bash
#slaveip=`ifconfig eth1 | grep -w inet | awk '{print $2'};`
slaveip=`cat /etc/slaveip`
if [[ $(rpm -qa | grep -i mysql-community-server) == *mysql-community-server-8* ]]; then
   echo "Mysql removing in slave server:"
   systemctl stop mysqld
   mv /etc/my.cnf /etc/my.cnf_`date +"%d-%m-%Y-%s"`
   mv /var/lib/mysql /var/lib/mysql_`date +"%d-%m-%Y-%s"`
   timeout 240s dnf remove mysql-community-server -y >> /tmp/server_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql removal failed, please check issue"
   exit 5
else
echo "OK"
fi
else
echo "Mysql not installed in master server"
fi
echo "Removing mysql repo in slave server:"
if [[ $(rpm -qa | grep -i mysql80-community-release-el8-5.noarch) == mysql80-community-release-el8-5.noarch ]]; then
  timeout 120s  yum remove mysql80-community-release* -y >> /tmp/server_reset.log 2>&1
fi
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql repo uninstallation failed, please check issue"
else
echo "OK"
fi
