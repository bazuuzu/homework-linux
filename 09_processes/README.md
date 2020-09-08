## Написать свою реализацию ps ax используя анализ /proc

Будем анализировать файл /proc/$PID/stat

Из него достанем информацию о PID, PPID, State, NICE, Priority, tcomm

Получился следующий скрипт

```
#!/bin/bash

psshow=`ls /proc | grep -Eo '[0-9]{1,5}' | sort -n`

echo "-------------------------------------"
echo "PID       PPID    State   NICE    Priority        tcomm"

for i in $psshow
    do
        awk -F " " '{print $1,"\011",$4,"\011",$3,"\011",$19,"\011",$18,"\011",$2}' /proc/$i/stat
    done

echo "Всего процессов:"
ls /proc | grep -Eo '[0-9]{1,5}' | sort -n | wc -l
```

Вывод получается:
```
[root@q ~]# ./ps.sh 
-------------------------------------
PID     PPID    State   NICE    Priority        tcomm
1        0       S       0       20      (systemd)
2        0       S       0       20      (kthreadd)
...
Всего процессов:
87
```

"\011" - Табуляция для красивого вида

Чтобы запустить скрипт достаточно клонировать репозиторий и запустить ./ps.sh из папки homework-linux/09_processes, предварительно дав скрипту chmod +x