#!/bin/bash

# Устанавливаем утилиты
yum install nfs-utils nano -y
# Добавляем в автозагрузку firewalld
systemctl enable firewalld
# Стартуем firewall
systemctl start firewalld
# Прописываем порты
# Список портов выяснил, примонтировав на клиенте папку с выключенным firewalld
# командой netstat -tulpn (требует пакетов net-tools)
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --permanent --add-port=111/udp
firewall-cmd --permanent --add-port=111/tcp
firewall-cmd --permanent --add-port=2049/udp
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --permanent --add-port=1110/tcp
firewall-cmd --permanent --add-port=1110/udp
firewall-cmd --permanent --add-port=4045/tcp
firewall-cmd --permanent --add-port=4045/udp
firewall-cmd --permanent --add-port=344/tcp         
firewall-cmd --permanent --add-port=3355/tcp              
firewall-cmd --permanent --add-port=3348/tcp      
firewall-cmd --permanent --add-port=835/tcp                               
firewall-cmd --permanent --add-port=351/udp         
firewall-cmd --permanent --add-port=2294/udp       
firewall-cmd --permanent --add-port=3355/udp     
firewall-cmd --permanent --add-port=3348/udp      
firewall-cmd --permanent --add-port=344/udp                          
firewall-cmd --reload
# Создаём папку и выдаём права
mkdir /mnt/upload
chown -R nfsnobody:nfsnobody /mnt/upload/
chmod -R 777 /mnt/upload
# Прописываем настройки доступа к NFS-серверу
echo "/mnt/upload 192.168.50.11(rw,sync,root_squash,no_subtree_check)" > /etc/exports
# Ставим в автозагрузку и включаем службы
systemctl enable rpcbind nfs-server
systemctl start rpcbind nfs-server
