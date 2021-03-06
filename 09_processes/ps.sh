#!/bin/bash

psshow=`ls /proc | grep -Eo '[0-9]{1,5}' | sort -n`

echo "-------------------------------------"
echo "PID       PPID    State   NICE    Priority        tcomm"

for i in $psshow
    do
        awk -F " " '{print $1,"\011",$4,"\011",$3,"\011",$19,"\011",$18,"\011",$2}' /proc/$i/stat
    done 2> /dev/null

echo "-------------------------------------"
echo "Всего процессов:"

count=`ls /proc | grep -Eo '[0-9]{1,5}' | sort -n | wc -l`
echo $((count-5))