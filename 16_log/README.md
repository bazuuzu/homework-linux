## Journald

Склонировать репозиторий и перейти в папку homework-linux/16_log<br>
Затем запустить стенд Vagrant

Имеются 2 машины: nginx и log

- На nginx - установлен nginx и настроен systemd-journal-upload (который почему-то падает после перезагрузки, нужно делать systemctl restart systemd-journal-upload.service). Сохраняет сообщения аудита и отсылает их на сервер log

- На log - центральный сервер логов с journald: systemd-journal-gateway и systemd-journal-remote. Настроен приём событий аудита изменения конфига nginx

На сервер log присылаются все логи, в том числе nginx. Для проверки сделать:
```
journalctl -D /var/log/journal/remote --follow
```
Для проверки сообщений аудита на сервере nginx нужно изменить конфиг nginx по пути /etc/nginx/nginx.conf<br>
И на сервере log сделать:
```
ausearch -k nginx
```