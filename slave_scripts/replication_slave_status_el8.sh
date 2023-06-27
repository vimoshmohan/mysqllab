#!/bin/bash
export TERM=xterm-256color
banner()
{
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}
banner "Replication status"
threshold=500
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
fi
#if [ "$Seconds_Behind_Master" -gt "$threshold" ]
#then
#echo "Replication lag is greater than 500 on server"
#fi
