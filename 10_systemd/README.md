- Vagrantfile - тестовая среда
- watchlog.sh - скрипт для 1 задания
- watchlog.log - лог-файл дял 1 задания
- first.conf - конфигурация httpd для 3 задания
- second.conf - конфигурация httpd для 3 задания


## Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

Сначала создал файл с конфигурацией для сервиса в /etc/sysconfig/watchlog - из неё сервис будет брать необходимые переменные

```
[root@q vagrant]# cat /etc/sysconfig/watchlog
# Configuration file for my watchdog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Затем создал сам файл лога с рандомными строками и словом "ALERT" на этих строках /var/log/watchlog.log

Создал скрипт в /opt/watchlog.sh

```
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
        logger "$DATE: I found word, Master!"
else
        exit 0
fi
```

Сделал chmod +x /opt/watchlog.sh

Создал юнит для сервиса в /etc/systemd/system/watchlog.service

```
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

И для таймера в /etc/systemd/system/watchlog.timer

```
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

```
[root@q vagrant]# ll /etc/systemd/system/ | grep watchlog
-rw-r--r--. 1 root root  141 Sep 20 16:00 watchlog.service
-rw-r--r--. 1 root root  165 Sep 20 16:01 watchlog.timer
```

Теперь нужно запустить timer

```
[root@q vagrant]# systemctl start watchlog.timer
```

Проверяем

```
[root@q vagrant]# tail -f /var/log/messages
Sep 20 16:17:46 localhost systemd-logind: New session 5 of user vagrant.
Sep 20 16:17:46 localhost systemd: Starting Session 5 of user vagrant.
Sep 20 16:17:49 localhost su: (to root) vagrant on pts/0
Sep 20 16:20:19 localhost systemd: Started Run watchlog script every 30 second.
Sep 20 16:20:19 localhost systemd: Starting Run watchlog script every 30 second.
Sep 20 16:20:56 localhost chronyd[656]: Source 46.17.46.226 replaced with 185.209.85.222
Sep 20 16:21:40 localhost su: (to root) vagrant on pts/1
Sep 20 16:23:28 localhost systemd: Starting My watchlog service...
Sep 20 16:23:28 localhost root: Sun Sep 20 16:23:28 UTC 2020: I found word, Master!
Sep 20 16:23:28 localhost systemd: Started My watchlog service.
Sep 20 16:24:05 localhost systemd: Starting My watchlog service...
Sep 20 16:24:05 localhost root: Sun Sep 20 16:24:05 UTC 2020: I found word, Master!
Sep 20 16:24:05 localhost systemd: Started My watchlog service.
```

## Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно также называться.

Если не установлено, то установить
```
yum install epel-release -y && yum install spawn-fcgi php php-cli
```

Необходимо раскомментировать строки с переменными в /etc/sysconfig/spawn-fcgi

```
[root@q vagrant]# cat /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```

Юнит файл:

```
[root@q vagrant]# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Проверяем:

```
[root@q vagrant]# systemctl start spawn-fcgi
[root@q vagrant]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-09-20 16:35:25 UTC; 5s ago
 Main PID: 3800 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─3800 /usr/bin/php-cgi
           ├─3801 /usr/bin/php-cgi
           ├─3802 /usr/bin/php-cgi
           ├─3803 /usr/bin/php-cgi
           ├─3804 /usr/bin/php-cgi
           ├─3805 /usr/bin/php-cgi
           ├─3806 /usr/bin/php-cgi
           ├─3807 /usr/bin/php-cgi
           ├─3808 /usr/bin/php-cgi
           ├─3809 /usr/bin/php-cgi
           ├─3810 /usr/bin/php-cgi
           ├─3811 /usr/bin/php-cgi
           ├─3812 /usr/bin/php-cgi
           ├─3813 /usr/bin/php-cgi
           ├─3814 /usr/bin/php-cgi
           ├─3815 /usr/bin/php-cgi
           ├─3816 /usr/bin/php-cgi
           ├─3817 /usr/bin/php-cgi
           ├─3818 /usr/bin/php-cgi
           ├─3819 /usr/bin/php-cgi
           ├─3820 /usr/bin/php-cgi
           ├─3821 /usr/bin/php-cgi
           ├─3822 /usr/bin/php-cgi
           ├─3823 /usr/bin/php-cgi
           ├─3824 /usr/bin/php-cgi
           ├─3825 /usr/bin/php-cgi
           ├─3826 /usr/bin/php-cgi
           ├─3827 /usr/bin/php-cgi
           ├─3828 /usr/bin/php-cgi
           ├─3829 /usr/bin/php-cgi
           ├─3830 /usr/bin/php-cgi
           ├─3831 /usr/bin/php-cgi
           └─3832 /usr/bin/php-cgi

Sep 20 16:35:25 q systemd[1]: Started Spawn-fcgi startup service by Otus.
Sep 20 16:35:25 q systemd[1]: Starting Spawn-fcgi startup service by Otus...
```

## Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

Устанавливаем httpd, если ещё не установлен

```
yum install -y httpd
```

Создаём файл /etc/systemd/system/httpd@.service, копируя и изменив содержимое из /usr/lib/systemd/system/httpd.service. Обязательно должно быть в названии юнита @. Добавляем -%I в строку EnvironmentFile=/etc/sysconfig/httpd-%I

```
[root@q vagrant]# cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
[root@q vagrant]# nano /etc/systemd/system/httpd@.service
[root@q vagrant]# cat /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Создадим конфигурационные файлы

```
[root@q vagrant]# cat /etc/sysconfig/httpd-first
# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
[root@q vagrant]# cat /etc/sysconfig/httpd-second
# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```

Соответственно в директории с конфигами httpd должны лежать два конфига, в нашем случае это будут /etc/httpd/conf/first.conf и /etc/httpd/conf/second.conf
Сами конфиги возьмём из этого репозитория. Файлы: first.conf и second.conf
Там изменены строки для первого:
PidFile /var/run/httpd-first.pid
Listen 80
Для второго:
PidFile /var/run/httpd-second.pid
Listen 8080

Запускаем и проверяем

```
[root@q vagrant]# systemctl start httpd@second
[root@q vagrant]# systemctl start httpd@first
[root@q vagrant]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=7252,fd=4),("httpd",pid=7251,fd=4),("httpd",pid=7250,fd=4),("httpd",pid=7249,fd=4),("httpd",pid=7248,fd=4),("httpd",pid=7247,fd=4))
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=7236,fd=4),("httpd",pid=7235,fd=4),("httpd",pid=7234,fd=4),("httpd",pid=7233,fd=4),("httpd",pid=7232,fd=4),("httpd",pid=7231,fd=4))
```