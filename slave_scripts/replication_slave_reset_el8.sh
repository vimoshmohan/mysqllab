#!/bin/bash
slaveip=`cat /etc/slaveip`
masterip=`cat /etc/masterip`
if [[ $(rpm -qa | grep -i mysql-community-server) == *mysql-community-server-8* ]]; then
   echo "Mysql removing in slave server:"
   systemctl stop mysqld
   mv /etc/my.cnf /etc/my.cnf_`date +"%d-%m-%Y-%s"`
   mv /var/lib/mysql /var/lib/mysql_`date +"%d-%m-%Y-%s"`
   timeout 180s dnf remove mysql-community-server -y >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql removal failed, please check issue"
   exit 5
else
echo "OK"
fi
else
echo "Mysql not installed in slave server"
fi
echo "Installing mysql repo in slave server:"
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
echo "Installing mysql server in slave server:"
yum install -y mysql-community-server  >> /tmp/replication_reset.log 2>&1

if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql Installation failed, please check issue"
   exit 5
else
echo "OK"
systemctl enable mysqld
systemctl start mysqld
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysql service failed, please check issue"
   exit 5
fi
fi
##mysql --connect-expired-password -u root -p`echo "$(grep -i root /var/log/mysqld.log | tail -1 | cut -d ':' -f4| awk '{print $1}';)"` -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '#Q5fdjYUF1XFSi9H10';flush privileges;" >>  /tmp/replication_script.log 2>&1
mysql --connect-expired-password -u root -p`echo "$(grep -i root /var/log/mysqld.log | tail -1 |awk '{print $13}';)"` -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '#Q5fdjYUF1XFSi9H10';flush privileges;" >>  /tmp/replication_script.log 2>&1
systemctl stop mysqld
cat >/etc/my.cnf <<EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
relay-log=/var/lib/mysql/db2-relay-log
relay-log-space-limit = 4G
read-only=1
server-id=101
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
   exit 5
fi
mysql -e "stop slave;reset slave all;"
mysql -e "CHANGE MASTER TO MASTER_HOST='$masterip', MASTER_USER='replicant', MASTER_PASSWORD='#Q5fdjYUF1XFSi9H9',GET_MASTER_PUBLIC_KEY=1;"
zcat /tmp/all.sql.gz | mysql 
if [[ $(echo $?) -gt 0 ]]; then
   echo "Mysqldump restore failed"
   exit 5
else
echo "Connectivity from slave server to master server:"
yum install nc  >> /tmp/replication_reset.log 2>&1
timeout 30s nc -zv $masterip 3306  >> /tmp/replication_reset.log 2>&1
if [[ $(echo $?) -gt 0 ]]; then
   echo "Slave to master connectivity failed"
   exit 5
else
echo "OK"
fi
fi
mysql -e "flush privileges; start slave"
sleep 60s
Last_IO_Error=`mysql -e "show slave status\G"|grep -i Last_IO_Error|awk -F ":" '{print $2}'|sed 's/ //g'`
Last_SQL_Error=`mysql -e "show slave status\G"|grep -i Last_SQL_Error|awk -F ":" '{print $2}'|sed 's/ //g'`
Last_Error=`mysql -e "show slave status\G"|grep -i Last_Error|awk -F ":" '{print $2}'|sed 's/ //g'`
#Seconds_Behind_Master=`mysql -e "show slave status\G"|grep -i Seconds_Behind_Master|awk -F ":" '{print $2}'|sed 's/ //g'`
io_running=`mysql -e "show slave status\G"|grep -w Slave_IO_Running |awk -F ":" '{print $2}'|sed 's/ //g'`
sql_running=`mysql -e "show slave status\G"|grep -w Slave_SQL_Running |awk -F ":" '{print $2}'|sed 's/ //g'`
if [ -z "$Last_IO_Error" ] && [ -z "$Last_SQL_Error" ] && [ -z "$Last_Error" ] && [[ "$io_running" == Yes ]] &&  [[ "$sql_running" == Yes ]]
then
  green='\033[0;42m'
  # Clear the color after that
  clear='\033[0m'
  printf "${green}Replication Status${clear}! \n"
  mysql -e "show slave status\G"|egrep 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'
  green='\033[0;42m'
  # Clear the color after that
  clear='\033[0m'
  printf "${green}Replication working fine${clear} \n"
else
echo "replication not working for server,please investigate issue"
mysql -e "show slave status\G"|egrep 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'
fi
