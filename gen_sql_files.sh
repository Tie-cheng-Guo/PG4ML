#!/bin/bash

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

extversion=`grep default_version pg4ml.control | sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/"`
sqlfile="pg4ml--"$extversion".sql"
sqlfile2021="pg4ml--2.0--"$extversion".sql"

if [ -f $sqlfile ]
then
    rm -f $sqlfile
fi

# build 00_for_patch
read_dir 'sql/00_for_patch' | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done

# build 01_type_schema_extension
read_dir 'sql/01_type_schema_extension' | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile
echo "" >> $sqlfile

# build 2.0--2.1 patch
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done

# build 02_table_view
read_dir 'sql/02_table_view' | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile
echo "" >> $sqlfile

# build 2.0--2.1 patch
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done

# build 03_function
read_dir 'sql/03_function' | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile
echo "" >> $sqlfile

# build 2.0--2.1 patch
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done

# build 04_procedure
read_dir 'sql/04_procedure' | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile
echo "" >> $sqlfile

# build 2.0--2.1 patch
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done

# build 06_data_initial
read_dir 'sql/06_data_initial' | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile
echo "" >> $sqlfile

# build 2.0--2.1 patch
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done

# build 09_operator
read_dir 'sql/09_operator' | \
grep -v "/11_test/" | \
grep -v "/delete/" | \
grep "\.sql$" | \
while read line;
do
cat $line >> $sqlfile
echo "" >> $sqlfile

# build 2.0--2.1 patch
cat $line >> $sqlfile2021
echo "" >> $sqlfile2021
done