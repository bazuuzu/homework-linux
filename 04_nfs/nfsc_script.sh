#!/bin/bash

# Устанавливаем утилиты
yum install nfs-utils nano -y
# Ставим в автозагрузку и стартуем службу
systemctl start rpcbind
systemctl enable rpcbind
# Создаём папку в монтировании
mkdir /mnt/upload
# Прописываем в автомонтирование папку
echo "192.168.50.10:/mnt/upload /mnt/upload nfs udp,nfsvers=3 0 0" >> /etc/fstab
# Примонтируем всё из fstab
mount -a
