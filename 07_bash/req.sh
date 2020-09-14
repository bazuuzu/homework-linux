#!/bin/bash

#ENV
old_str=`cat env.txt`
curr_str=`wc -l access.log | awk -F " " '{print $1}'`
lockfile=/tmp/localfile

#Функция подсчёта временного промежутка
timeinterval()
    {
        echo "Временной интервал:" > send.txt
        diap1=$(tail -n+$old_str access.log | awk -F " " '{print $4}' | cut -c 2- | awk 'NR==1')
        diap2=$(tail -n+$old_str access.log | awk -F " " '{print $4}' | cut -c 2- | awk 'END{print}')
        echo "$diap1 - $diap2" >> send.txt
    }

#Функция подсчёта значений

parsing()
{
        #X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов
        echo "IP адресов с наибольшим кол-вом запросов:" >> send.txt
        tail -n+$old_str access.log | awk -F "-" '{print $1}' | sort -nr | uniq -c | sort -nr >> send.txt
        #Y запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска
        echo "Наиболее запрашиваемые адреса:" >> send.txt
        tail -n+$old_str access.log | awk -F " " '{print $7}' | sort -nr | uniq -c | sort -nr >> send.txt
        #все ошибки c момента последнего запуска
        echo "Все ошибки:" >> send.txt
        tail -n+$old_str access.log | awk -F '"' '{print $3}' | awk -F " " '{print $1}' | grep -P '4..|5..' | sort | uniq -c | sort -nr >> send.txt
        #список всех кодов возврата с указанием их кол-ва с момента последнего запуска
        echo "Все коды возврата:" >> send.txt
        tail -n+$old_str access.log | awk -F '"' '{print $3}' | awk -F " " '{print $1}' | sort | uniq -c | sort -nr >> send.txt
}

#Функция изменения строки
str_chn()
{
old_str=`wc -l access.log | awk -F " " '{print $1}'`
echo ${old_str} > env.txt
}

#Функция, отслеживающая стирание access.log
log_erased()
{
    if (($old_str > $curr_str));
    then
        old_str=0
        echo ${old_str} > env.txt
    else
        sleep 10s
    fi
}

#Защита от повторного запуска
trap_file()
{
        if ( set -o noclobber; echo `ps -a | grep req.sh` > "$lockfile") 2> /dev/null;
                then
                trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
                while true
                        do
                        log_erased
                        timeinterval
                        parsing
                        str_chn
                        sleep 10s
                        mail -s "Stat access.log" root@localhost < send.txt
                        exit
                done
                rm -rf "$lockfile"
                trap - INT TERM EXIT
        else
                echo "Failed to launch script"
                echo "Held by $(cat $lockfile)"
        fi
}

trap_file