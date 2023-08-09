#!/bin/bash

# 准备活动
# 切换到 linux postgres 用户或其他管理员用户

#cd $(dirname $0)
# chmod 755 ./install.sh

cd $(dirname $0)/..
root_path=`pwd`
# find -type f | xargs dos2unix

function read_dir(){
for file in `ls $1 | sort` #注意此处这是两个反引号，表示运行系统命令
do
 if [ -d $1"/"$file ] #注意此处之间一定要加上空格，否则会报错
 then
 read_dir $1"/"$file
 else
 echo $1"/"$file #在此处处理文件即可
 fi
done
}

#读取第一个参数

read_dir $root_path | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
psql -f $line
done
# xargs psql -h "$node_ipv4_master" -U "$fdw_username_master" -p "$node_port_master" -W"$fdw_password_master" -f

