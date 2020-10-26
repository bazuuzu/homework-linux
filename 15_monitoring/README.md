Настройка мониторинга
Настроить дашборд с 4-мя графиками
1) память
2) процессор
3) диск
4) сеть

настроить на одной из систем
- zabbix (использовать screen (комплексный экран))
- prometheus - grafana

### Был выбран Zabbix

Устанавливалось на Ubuntu 20.04

Подключил репозиторий zabbix 5.0
```
wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+bionic_all.deb
dpkg -i zabbix-release_5.0-1+bionic_all.deb
```
Устанавливаем
```
apt install zabbix-server-mysql zabbix-frontend-php -y
apt install nginx php-fpm -y
```
Запускаем скрипт начальной конфигурации mysql и задаем пароль для root
```
/usr/bin/mysql_secure_installation
```
Cоздадим базу данных, пользователя zabbix, и заполним базу
```
mysql -uroot -p
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabpassword';
exit
zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -p zabbix
```
Редактируем файл конфигурации сервера заббикс /etc/zabbix/zabbix_server.conf

Запускаем zabbix и добавляем в автозагрузку

Запускаем nginx, который у нас будет выступать в качестве web сервера

Нам нужно сделать конфиг nginx для работы web интерфейса zabbix. Если у вас nginx работает на том же сервере, где сам zabbix, и других виртуальных хостов нет и не будет, то правьте сразу дефолтный — /etc/nginx/sites-available/default.conf. Приводим его к следующему виду:

```
server {
    listen       80;
    server_name  localhost;
    root /usr/share/zabbix;

    location / {
    index index.php index.html index.htm;
    }

    location ~ \.php$ {
    fastcgi_pass unix:/run/php/php7.2-fpm.sock; # проверьте этот путь, для разных версий php он будет разный
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    include fastcgi_params;
    fastcgi_param PHP_VALUE " 
    max_execution_time = 300
    memory_limit = 128M
    post_max_size = 16M
    upload_max_filesize = 2M
    max_input_time = 300
    date.timezone = Europe/Moscow
    always_populate_raw_post_data = -1
    ";
    fastcgi_buffers 8 256k;
    fastcgi_buffer_size 128k;
    fastcgi_intercept_errors on;
    fastcgi_busy_buffers_size 256k;
    fastcgi_temp_file_write_size 256k;
        }
}
```

```
nginx -t
nginx -s reload
```

Переходим по адресу сервера
Вводим пароль от БД
Логинимся:
Admin:zabbix

### Установка Zabbix-agent

```
apt install zabbix-agent -y
nano /etc/zabbix/zabbix_agentd.conf
systemctl start zabbix-agent
systemctl enable zabbix-agent
```

## Результат ДЗ

Настроенный дашборд <br>
![Dashboard.png](https://github.com/bazuuzu/homework-linux/blob/master/15_monitoring/Dashboard.png)

Настроенный комплексный экран <br>
![Screen.png](https://github.com/bazuuzu/homework-linux/blob/master/15_monitoring/Screen.png)

Настроенный комплексный экран в шаблоне для каждого из узлов <br>
![Template Screen.png](https://github.com/bazuuzu/homework-linux/blob/master/15_monitoring/Template%20Screen.png)