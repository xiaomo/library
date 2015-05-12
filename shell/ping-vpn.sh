#!/bin/bash
# Program:
#       这个程序用来ping鲨鱼vpn的server，看谁快
# History:
# V1.0	2015/04/08	moming

array=$(cat ~/work/script/vpn_server.txt  | awk 'BEGIN {FS=" "} {print $1}' | grep '[0-9]' |sed 's/'\t'//g')

for ip in ${array[@]}
do
	result=$(ping -c 2 -w 1 ${ip} | grep "time=" | awk 'BEGIN {FS=" "} {print $(NF-1) $(NF)}')
	echo -e "\033[32m " ${ip}" \033[0m"
	echo -e "\033[37m " ${result}" \033[0m"
done

exit 0
