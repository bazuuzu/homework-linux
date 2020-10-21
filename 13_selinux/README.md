1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.

## Решение задачи 1

Проверяем статус SELinux
```
[root@SELinux vagrant]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31
```

Включен, окей. Устанавливаем nginx
```
yum install -y epel-release
yum install -y nginx
```
```
[root@SELinux vagrant]# systemctl start nginx
root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-21 11:37:06 UTC; 1s ago
```
```
[root@SELinux vagrant]# curl http://192.168.11.150/
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
```
Проверяем, какие порты записаны
```
[root@SELinux vagrant]# semanage port -l | grep http_
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```
Меняем порт в конфиге nginx с 80 на 8888

Получили ошибку:
```
[root@SELinux vagrant]# nginx -t              
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@SELinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Wed 2020-10-21 11:45:10 UTC; 4s ago
  Process: 3348 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3395 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 3393 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3350 (code=exited, status=0/SUCCESS)

Oct 21 11:45:10 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 21 11:45:10 SELinux nginx[3395]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 21 11:45:10 SELinux nginx[3395]: nginx: [emerg] bind() to 0.0.0.0:8888 failed (13: Permission denied)
Oct 21 11:45:10 SELinux nginx[3395]: nginx: configuration file /etc/nginx/nginx.conf test failed
Oct 21 11:45:10 SELinux systemd[1]: nginx.service: control process exited, code=exited status=1
Oct 21 11:45:10 SELinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Oct 21 11:45:10 SELinux systemd[1]: Unit nginx.service entered failed state.
Oct 21 11:45:10 SELinux systemd[1]: nginx.service failed.
```

Проверяем, через audit2why файл логов аудита
```
[root@SELinux vagrant]# audit2why < /var/log/audit/audit.log 
type=AVC msg=audit(1603280710.273:992): avc:  denied  { name_bind } for  pid=3395 comm="nginx" src=8888 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly. 
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
Тут уже предлагается решение

- переключатели setsebool

-P - означает, что будет применено и после перезагрузки

```
[root@SELinux vagrant]# setsebool -P nis_enabled 1
[root@SELinux vagrant]# systemctl start nginx
[root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-21 11:53:41 UTC; 3s ago
```

Возвращаем на setsebool -P nis_enabled 0 - nginx не запускается теперь. Работаем дальше

- добавление нестандартного порта в имеющийся тип

Проверяем, видим, что надо менять http_port_t

```
[root@SELinux vagrant]# semanage port -l | grep http_
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```
Меняем
```
[root@SELinux vagrant]# semanage port -a -t http_port_t -p tcp 8888
[root@SELinux vagrant]#systemctl start nginx
[root@SELinux vagrant]#systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-21 12:02:18 UTC; 3s ago
```
Чтобы откатить эти изменения, просто делаем
```
[root@SELinux vagrant]# semanage port -d -t http_port_t -p tcp 8888
[root@SELinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```

- формирование и установка модуля SELinux

Очищаем audit.log
```
[root@SELinux vagrant]# echo > /var/log/audit/audit.log
[root@SELinux vagrant]# audit2why < /var/log/audit/audit.log 
Nothing to do
```
Включаем в SELinux режим permissive
```
[root@SELinux vagrant]# setenforce 0
```
Запускаем службу и смотрим, что в логах
```
[root@SELinux vagrant]# systemctl start nginx
[root@SELinux vagrant]# audit2why < /var/log/audit/audit.log 
type=AVC msg=audit(1603282707.058:1035): avc:  denied  { name_bind } for  pid=24387 comm="nginx" src=8888 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=1

        Was caused by:
        The boolean nis_enabled was set incorrectly. 
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
Формируем модуль с правилами для SELinux из данных каталога
```
[root@SELinux vagrant]# audit2allow -M httpd_add --debug < /var/log/audit/audit.log
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i httpd_add.pp

[root@SELinux vagrant]# ll
total 8
-rw-r--r--. 1 root root 964 Oct 21 12:30 httpd_add.pp
-rw-r--r--. 1 root root 261 Oct 21 12:30 httpd_add.te
```
Загружаем модуль в ядро и смотрим, что он там появился
```
[root@SELinux vagrant]# semodule -i httpd_add.pp 
[root@SELinux vagrant]# semodule -l | grep httpd_add
httpd_add       1.0
[root@SELinux vagrant]# systemctl start nginx
[root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-21 12:18:27 UTC; 16min ago
```
Всё ок, доступно


yum install -y settroubleshoot-server 
sealert -a /var/log/audit/audit.log - утилита для анализа лога. Сама предлагает различные варианты

## Решение задачи 2

2. Обеспечить работоспособность приложения при включенном selinux.
- Развернуть приложенный стенд
https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.

Клонируем репозиторий https://github.com/mbfx/otus-linux-adm.git, переходим в selinux_dns_problems и разворачиваем стенд

Подключаемся на client и делаем оттуда
```
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> 
```
Получили ошибку

### Выясняем

Заходим на ns01

Очистил аудит.лог
```
echo > /var/log/audit/audit.log
```

audit2why показал следующее
```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1603292366.602:1823): avc:  denied  { create } for  pid=4825 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```

Генерируем модуль

```
[root@ns01 vagrant]# audit2allow -M dns_mod_add --debug < /var/log/audit/audit.log
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i dns_mod_add.pp

[root@ns01 vagrant]# semodule -i dns_mod_add.pp 
```

Очислил лог <br>
Пробую опять на клиенте<br>
Получил ошибку<br>

Опять ошибка в audit.log, только уже write
```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1603292558.359:1833): avc:  denied  { write } for  pid=4825 comm="isc-worker0000" path="/etc/named/dynamic/named.ddns.lab.view1.jnl" dev="sda1" ino=532629 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```
Повторяем процедуру <br>
Очищаем лог, пробуем опять с клиента <br>
Опять ошибка, в логе ничего <br>
```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log
Nothing to do
```
Смотрим в лог /var/log/messages
```
Oct 21 15:02:42 localhost python: SELinux is preventing isc-worker0000 from write access on the file /etc/named/dynamic/named.ddns.lab.view1.jnl.#012#012*****  Plugin catchall_labels (83.8 confidence) suggests   *******************#012#012If you want to allow isc-worker0000 to have write access on the named.ddns.lab.view1.jnl file#012Then you need to change the label on /etc/named/dynamic/named.ddns.lab.view1.jnl#012Do#012# semanage fcontext -a -t FILE_TYPE '/etc/named/dynamic/named.ddns.lab.view1.jnl'#012where FILE_TYPE is one of the following: afs_cache_t, dnssec_trigger_var_run_t, initrc_tmp_t, ipa_var_lib_t, krb5_host_rcache_t, krb5_keytab_t, named_cache_t, named_log_t, named_tmp_t, named_var_run_t, named_zone_t, puppet_tmp_t, user_cron_spool_t, user_tmp_t.#012Then execute:#012restorecon -v '/etc/named/dynamic/named.ddns.lab.view1.jnl'#012#012#012*****  Plugin catchall (17.1 confidence) suggests   **************************#012#012If you believe that isc-worker0000 should be allowed write access on the named.ddns.lab.view1.jnl file by default.#012Then you should report this as a bug.#012You can generate a local policy module to allow this access.#012Do#012allow this access for now by executing:#012# ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000#012# semodule -i my-iscworker0000.pp#012
```
Там рекомендуется сделать: ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000 | semodule -i my-iscworker0000.pp
Делаем
На шаге audit2allow -M my-iscworker0000 просто зависло
Очистим лог, попробуем ещё раз с клиента. На клиенте ошибка, но messages не выадёт ошибки по SELinux, только
```
Oct 21 15:33:22 localhost named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#36880/key zonetransfer.key: view view1: signer "zonetransfer.key" approved
Oct 21 15:33:22 localhost named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#36880/key zonetransfer.key: view view1: updating zone 'ddns.lab/IN': adding an RR at 'www.ddns.lab' A 192.168.50.15
Oct 21 15:33:22 localhost named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#36880/key zonetransfer.key: view view1: updating zone 'ddns.lab/IN': error: journal open failed: no more
```
Смотрим, что в службе
```
[root@ns01 vagrant]# systemctl status named 
● named.service - Berkeley Internet Name Domain (DNS)
   Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-10-21 14:56:17 UTC; 39min ago
  Process: 4823 ExecStart=/usr/sbin/named -u named -c ${NAMEDCONF} $OPTIONS (code=exited, status=0/SUCCESS)
  Process: 4821 ExecStartPre=/bin/bash -c if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi (code=exited, status=0/SUCCESS)
 Main PID: 4825 (named)
   CGroup: /system.slice/named.service
           └─4825 /usr/sbin/named -u named -c /etc/named.conf

Oct 21 15:02:38 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#8832/key zonetransfer.key: view view1: sign...proved
Oct 21 15:02:38 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#8832/key zonetransfer.key: view view1: upda....50.15
Oct 21 15:02:38 ns01 named[4825]: /etc/named/dynamic/named.ddns.lab.view1.jnl: create: permission denied
Oct 21 15:02:38 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#8832/key zonetransfer.key: view view1: upda... error
Oct 21 15:05:28 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#22431/key zonetransfer.key: view view1: sig...proved
Oct 21 15:05:28 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#22431/key zonetransfer.key: view view1: upd....50.15
Oct 21 15:05:28 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#22431/key zonetransfer.key: view view1: upd...o more
Oct 21 15:33:22 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#36880/key zonetransfer.key: view view1: sig...proved
Oct 21 15:33:22 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#36880/key zonetransfer.key: view view1: upd....50.15
Oct 21 15:33:22 ns01 named[4825]: client @0x7f0b8c03c3e0 192.168.50.15#36880/key zonetransfer.key: view view1: upd...o more
Hint: Some lines were ellipsized, use -l to show in full.
```
Выдало ошибку доступа в /etc/named/dynamic/named.ddns.lab.view1.jnl: create: permission denied

Проверим контекст безопасности для файла
```
[root@ns01 vagrant]# ls -Z /etc/named/        
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
```
Он оказался: etc_t

Изменим контекст безопасности для файла

/etc/named/dynamic/named.ddns.lab.view1.jnl
```
[root@ns01 vagrant]# cat /etc/selinux/targeted/contexts/files/file_contexts | grep named
/etc/rndc.*     --      system_u:object_r:named_conf_t:s0
/var/named(/.*)?        system_u:object_r:named_zone_t:s0
```

Чтобы изменить навсегда нужно выполнить: If you want to permanently change the file context you need to use the **semanage fcontext** command. This will modify the SELinux labeling database. You will need to use restorecon to apply the labels. (https://linux.die.net/man/8/named_selinux, https://docs.fedoraproject.org/ru-RU/Fedora/13/html/Security-Enhanced_Linux/sect-Security-Enhanced_Linux-SELinux_Contexts_Labeling_Files-Persistent_Changes_semanage_fcontext.html)

```
[root@ns01 vagrant]# ls -Z /etc/named/dynamic/named.ddns.lab.view1.jnl 
-rw-r--r--. named named system_u:object_r:etc_t:s0       /etc/named/dynamic/named.ddns.lab.view1.jnl
[root@ns01 vagrant]# semanage fcontext -a -t named_zone_t /etc/named/dynamic/named.ddns.lab.view1.jnl
[root@ns01 vagrant]# restorecon -v /etc/named/dynamic/named.ddns.lab.view1.jnl 
restorecon reset /etc/named/dynamic/named.ddns.lab.view1.jnl context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
[root@ns01 vagrant]# ls -Z /etc/named/dynamic/named.ddns.lab.view1.jnl 
-rw-r--r--. named named system_u:object_r:named_zone_t:s0 /etc/named/dynamic/named.ddns.lab.view1.jnl
```
Делаем рестарт named и смотрим статус
```
[root@ns01 vagrant]# systemctl restart named
[root@ns01 vagrant]# systemctl status named
```
Никаких ошибок. Пробуем с клиента

Получилось

### Как вариант ещё:

Пробуем поменять контекст через chcon

Команда chcon вносит изменения в контекст SELinux для файлов. Однако, изменения, вносимые с помощью команды chcon не сохраняются после перемаркирования файловой системы или выполнения команды /sbin/restorecon. Политика SELinux контролирует может ли пользователь изменять контекст для файлов. При использовании команды chcon, пользователи предоставляют всю информацию или часть об изменении контекста SELinux. Некорректный тип файла обычно является причиной блокирования доступа SELinux.


```
[root@ns01 vagrant]# chcon -t named_zone_t /etc/named/dynamic/*
[root@ns01 vagrant]# chcon -t named_zone_t /etc/named/*
[root@ns01 vagrant]# ls -Z /etc/named/dynamic/
-rw-rw----. named named system_u:object_r:named_zone_t:s0 named.ddns.lab
-rw-rw----. named named system_u:object_r:named_zone_t:s0 named.ddns.lab.view1
-rw-r--r--. named named system_u:object_r:named_zone_t:s0 named.ddns.lab.view1.jnl
[root@ns01 vagrant]# ls -Z /etc/named/
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
```

На клиенте всё Ок