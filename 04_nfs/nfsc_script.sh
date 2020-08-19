#!/bin/bash

# Устанавливаем утилиты
yum install nfs-utils nano -y
# Ставим в автозагрузку и стартуем службу
systemctl start rpcbind
systemctl enable rpcbind
# Создаём папку в монтировании
mkdir /mnt/upload
# ---- Блок работает чере раз после перезагрузки ---- #
# Прописываем в автомонтирование папку
# echo "192.168.50.10:/mnt/upload /mnt/upload nfs noauto,x-systemd.automount,udp,nfsvers=3 0 0" >> /etc/fstab
# Примонтируем всё из fstab
# mount -a
# ---- Конец блока ---- #
# Смотируем через systemd. Имя файла должно содержать имя точки монтирования
echo -e "[Unit]\n  Description=nfs mount script\n  Requires=network-online.target\n  After=network-online.service\n\n[Mount]\n  What=192.168.50.10:/mnt/upload\n  Where=/mnt/upload\n  Options=udp,nfsvers=3\n  Type=nfs\n\n[Install]\n  WantedBy=multi-user.target" > /etc/systemd/system/mnt-upload.mount

systemctl enable mnt-upload.mount
systemctl start mnt-upload.mount