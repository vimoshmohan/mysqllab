#!/bin/bash
systemctl stop mysqld >> /tmp/replication_breakfix5.log 2>&1
status1=`echo $?`
sed -i 's/read-only/##read-only/g' /etc/my.cnf >> /tmp/replication_breakfix5.log 2>&1
status2=`echo $?`
systemctl start mysqld  >> /tmp/replication_breakfix5.log 2>&1
status3=`echo $?`
#day=$(date +%d%s)
mysql -e 'create database repdb;use repdb;CREATE TABLE movies1(title VARCHAR(50) NOT NULL,genre VARCHAR(30) NOT NULL,director VARCHAR(60) NOT NULL,release_year INT NOT NULL,PRIMARY KEY(title)); INSERT INTO movies1 VALUE ("Joker", "psychological thriller", "Todd Phillips", 2019);'
if [[ $status1 -gt 0 ]] || [[ $status2 -gt 0 ]] || [[ $status3 -gt 0 ]]
   then
   echo "Breakfix4 execution failed, please investigate issue"
   exit
else
   echo "Breakfix4 executed successfully,please try to fix the replication issue and execute replication status script once issue fixed"
fi
