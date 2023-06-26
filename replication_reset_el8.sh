#!/bin/bash
banner()
{
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}
banner "Replication setup Lab started"
banner "Replication setup Lab started" >> /tmp/replication_setup.log
#masterip=`ifconfig eth1 | grep -w inet | awk '{print $2'};`
echo "Enter private IP address of Master server:"
read masterip
A=`echo $masterip | awk '/^([0-9]{1,3}[.]){3}([0-9]{1,3})$/{print $1}'`
if [ -z $A ]; then
   red='\033[0;31m'
   # Clear the color after that
   clear='\033[0m'
   printf "${red}Please input a valid master IP address${clear} \n "
   exit
fi
echo "Enter private IP address of Slave server:"
read slaveip
echo "Enter ssh port of slave server:"
read sshport
B=`echo $slaveip | awk '/^([0-9]{1,3}[.]){3}([0-9]{1,3})$/{print $1}'`
if [ -z $B ]; then
   red='\033[0;31m'
   # Clear the color after that
   clear='\033[0m'
   printf "${red}Please input a valid slave IP address${clear} \n "
   exit
else
  green='\033[0;32m'
  # Clear the color after that
  clear='\033[0m'
  printf "${green}Replication Reset started${clear}! \n"
fi
banner "The server's IP addresses and slave ssh port"
echo "The master server IP is:" $masterip
echo "The slave server IP is :" $slaveip
echo "The slave server ssh port is:" $sshport
#echo $slaveip > /etc/slaveip
echo "Verifying passwordless ssh access for Root user to slave server:" $slaveip
#ssh -o StrictHostKeyChecking=no root@$slaveip "uptime" >> /tmp/replication_setup.log 2>&1
timeout 5s ssh -p $sshport -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root user passwordless ssh connectivity to slave server failed"
   exit
else
   echo " Root user passwordless ssh connectivity to slave server:"
   echo "OK"
fi
echo $masterip > /etc/masterip
echo $slaveip > /etc/slaveip
echo $sshport > /etc/sshport
timeout 120s scp -P $sshport -o StrictHostKeyChecking=no /etc/slaveip root@$slaveip:/etc  >> /tmp/replication_reset.log 2>&1
timeout 120s scp -P $sshport -o StrictHostKeyChecking=no /etc/masterip root@$slaveip:/etc  >> /tmp/replication_reset.log 2>&1
timeout 120s scp -P $sshport -o StrictHostKeyChecking=no /etc/sshport root@$slaveip:/etc  >> /tmp/replication_reset.log 2>&1
if [[ $(rpm -qa | grep -i mysql-community-server) == *mysql-community-server-8* ]]; then
   echo "Mysql removing in master server:"
   systemctl stop mysqld
   mv /etc/my.cnf /etc/my.cnf_`date +"%d-%m-%Y-%s"`
   mv /var/lib/mysql /var/lib/mysql_`date +"%d-%m-%Y-%s"`
   timeout 120s dnf remove mysql-community-server -y >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql Uninstallation failed, please check issue"
   exit
else
echo "OK"
fi
else
echo "Mysql not installed in master server"
fi
echo "Installing mysql repo in master server:"
if [[ $(rpm -qa | grep -i mysql80-community-release-el8-5.noarch) == mysql80-community-release-el8-5.noarch ]]; then
   echo "Mysql repo already installed"
else
timeout  60s yum install http://dev.mysql.com/get/mysql80-community-release-el8-5.noarch.rpm -y >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql repo installation failed, please check issue"
else
echo "OK"
fi
fi
echo "Installing mysql server in master server:"
timeout 180s dnf install mysql-community-server -y  >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql Instalaltion failed, please check issue"
   exit
else
echo "OK"
systemctl enable mysqld
systemctl start mysqld
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql service failed, please check issue"
   exit
fi
fi
##mysql --connect-expired-password -u root -p`echo "$(grep -i root /var/log/mysqld.log |tail -1 | cut -d ':' -f4| awk '{print $1}';)"` -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '#Q5fdjYUF1XFSi9H10';flush privileges;" >> /tmp/replication_reset.log 2>&1
mysql --connect-expired-password -u root -p`echo "$(grep -i root /var/log/mysqld.log | tail -1 |awk '{print $13}';)"` -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '#Q5fdjYUF1XFSi9H10';flush privileges;" >> /tmp/replication_setup.log 2>&1
systemctl stop mysqld
cat >/etc/my.cnf <<EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-bin=/var/lib/mysql/db01-binary-log
binlog-format=ROW
binlog-row-image=minimal
expire-logs-days=4
server-id=100
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
EOF
cat >/root/.my.cnf <<EOF
[client]
user=root
password="#Q5fdjYUF1XFSi9H10"
EOF
systemctl start mysqld
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql service failed, please check issue"
   exit
else
mysql -e "create user 'replicant'@'$slaveip' IDENTIFIED BY '#Q5fdjYUF1XFSi9H9';GRANT REPLICATION SLAVE ON *.* to 'replicant'@'$slaveip';flush privileges" >> /tmp/replication_reset.log 2>&1
fi
firewall-cmd --add-rich-rule='rule family=ipv4 source address="'$slaveip'" port port="3306" protocol=tcp accept' --permanent >> /tmp/replication_reset.log 2>&1
firewall-cmd --reload >> /tmp/replication_reset.log 2>&1
echo " Taking mysqldump: "
ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip "mv /tmp/all.sql.gz /tmp/all.sql.gz_`date +"%d-%m-%Y-%s"`" 
mysqldump --all-databases --source-data | gzip -1 > /tmp/all.sql.gz
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysqldump failed"
   exit
else
echo "OK"
echo "Copying dump file to slave server: "
scp -P $sshport -o StrictHostKeyChecking=no -pr /tmp/all.sql.gz root@$slaveip:/tmp/ >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Unable to copy dump to slave server"
   exit
else
echo "OK"
fi
fi
echo " Slave setup started:"
timeout 10s ssh -p $sshport -oBatchMode=yes -o StrictHostKeyChecking=no root@$slaveip echo  > /dev/null 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Root passwordless ssh connectivity to slave server failed"
   exit
else
echo "===================================slave server logs started=============" >> /tmp/replication_reset.log
#ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  "/tmp/replication_slave_reset_el8.sh"
ssh -p $sshport -o StrictHostKeyChecking=no root@$slaveip  "bash <(curl https://raw.githubusercontent.com/vimoshmohan/mysqllab/main/slave_scripts/replication_slave_reset_el8.sh)"
if [[ $(echo $?) -gt 0 ]]; then
   echo "Please check issue in slave server"
   exit
fi
fi
