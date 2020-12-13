Поднято 2 машины:

Схема

Устанавливаем на обе машины необходимые пакеты
```
yum install -y epel-release
yum install -y openvpn iperf3
```

Отключаем SELinux (До перезагрузки)

```
setenforce 0
```

Создаём файл-ключ
```
openvpn --genkey --secret /etc/openvpn/static.key
```

Создаём конфигурационный файл vpn-сервера
```
nano /etc/openvpn/server.conf
```
```
dev tap
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
Запускаем openvpn сервер и добавлāем в автозагрузку
```
[root@server vagrant]# systemctl start openvpn@server
[root@server vagrant]# systemctl enable openvpn@server
```

### Настраиваем клиент

Создаём конфигурационный файл клиента

```
nano /etc/openvpn/server.conf
```

На сервер клиента в директорию /etc/openvpn/ необходимо скопировать файл-ключ static.key, который был создан на сервере

```
cat > /etc/openvpn/static.key <<EOF
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
7d198c9f97ab712259fb375234ddb62f
e4a3df65bc84c2405616c1425ac836f5
30230bc50595977781f8abd061a7b10c
832b333b91bec0906d97aee38662d084
d95e67dd285563478401bac752b63e72
1137c1ce63c79954c2ba5536331f9bc4
bebce0338144d28fa7c6d36fa8c203d5
9ebd96359bf81cfd613b9d92bb321815
3596d85f13967f327c8ff3e1026d4c46
976798ace83c05ce23877617d4ee35c2
734408ff89f4337403501501a0da14cd
2dfb0c3ce23145a2fea17df2cba27afe
c9c60f698c25e4599c8a6e200fbcf1ed
acf3b7fedd3bb880df81b74d96023a31
843a2c94727c14307b4fd9cf0f5cf6d9
e1dd9d12b9e868641c1fd85982618f7d
-----END OpenVPN Static key V1-----
EOF
```

Запускаем на клиенте OpenVPN и добавляем в загрузку
```
[root@client vagrant]# systemctl start openvpn@server
[root@client vagrant]# systemctl enable openvpn@server
```

### Замеряем скорость в туннеле

```
[  4]   0.00-31.36  sec   524 MBytes   140 Mbits/sec  759             sender          
[  5]   0.00-31.00  sec   523 MBytes   142 Mbits/sec                  receiver    
```
Изменим с tap на tun
```
[root@server vagrant]# cat /etc/openvpn/server.conf
dev tun
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
```
[root@client vagrant]# cat /etc/openvpn/server.conf
dev tun
remote 192.168.10.10
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 192.168.10.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
Перезапускаем сервис и изменяем скорость заново. Результат:
TUN
```
[  4]   0.00-25.53  sec   492 MBytes   162 Mbits/sec  931             sender
[  5]   0.00-25.00  sec   491 MBytes   165 Mbits/sec                  receiver
```
TAP
```
[  4]   0.00-31.36  sec   524 MBytes   140 Mbits/sec  759             sender          
[  5]   0.00-31.00  sec   523 MBytes   142 Mbits/sec                  receiver    
```
Можно сделать следующий вывод: <br>
В лабораторной среде вышло, что tap немного быстрее, чем tun. В принципе, разница получилась не существенная. Однако, режим tap лучше использовать, когда нужно объединить физически два ethernet сегмента, так как он работает на L2 уровне модели OSI. В то время как TUN работает на уровне L3. TAP - для создание сетевого моста, тогда как TUN для маршрутизации.

## Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку

Поднимаем виртуалку Vagrant

После запуска ВМ отключаем SELinux (setenforce 0)

Переходим в директорию /etc/openvpn/ и инициализируем pki

```
[root@server vagrant]# cd /etc/openvpn/
[root@server openvpn]# /usr/share/easy-rsa/3.0.8/easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki
```

Сгенерируем необходимые ключи и сертификаты для сервера

```
[root@server openvpn]# echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa build-ca nopass
...
Your new CA certificate file for publishing is at:
/etc/openvpn/pki/ca.crt
```
```
[root@server openvpn]# echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa gen-req server nopass
...
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/server.req
key: /etc/openvpn/pki/private/server.key
```
```
[root@server openvpn]# echo 'yes' | /usr/share/easy-rsa/3.0.8/easyrsa sign-req server server
...
Certificate created at: /etc/openvpn/pki/issued/server.crt
```
```
[root@server openvpn]# /usr/share/easy-rsa/3.0.8/easyrsa gen-dh
...
DH parameters of size 2048 created at /etc/openvpn/pki/dh.pem
```
```
[root@server openvpn]# openvpn --genkey --secret ta.key
```
Сгенерируем сертификаты для клиента
```
[root@server openvpn]# echo 'client' | /usr/share/easy-rsa/3/easyrsa gen-req client nopass
...
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/client.req
key: /etc/openvpn/pki/private/client.key
```
```
[root@server openvpn]# echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req client client
...
Certificate created at: /etc/openvpn/pki/issued/client.crt
```

Создадим server.conf на RAS-сервере /etc/openvpn/server.conf
```
port 1194
proto tcp
dev tun
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/server.crt
key /etc/openvpn/pki/private/server.key
dh /etc/openvpn/pki/dh.pem
server 10.10.10.0 255.255.255.0
ifconfig-pool-persist ipp.txt
client-to-client
keepalive 10 120
comp-lzo
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
Копируем файлы на локальную машину
```
/etc/openvpn/pki/ca.crt
/etc/openvpn/pki/issued/client.crt
/etc/openvpn/pki/private/client.key
```
```
root@ubunzuzu:/home/novoselov/test# ll /etc/openvpn/
итого 48
drwxr-xr-x   4 root root  4096 дек 13 16:35 ./
drwxr-xr-x 155 root root 12288 дек 13 16:09 ../
-rw-r--r--   1 root root  1150 дек 13 16:36 ca.crt
drwxr-xr-x   2 root root  4096 дек 13 16:03 client/
-rw-r--r--   1 root root   189 дек 13 16:14 client.conf
-rw-r--r--   1 root root  4404 дек 13 16:36 client.crt
-rw-r--r--   1 root root  1703 дек 13 16:36 client.key
drwxr-xr-x   2 root root  4096 сен  5  2019 server/
-rwxr-xr-x   1 root root  1468 сен  5  2019 update-resolv-conf*
```
Конфигурация клиента на хостовой машине
```
dev tun
proto tcp
remote 127.0.0.1 1194
client
resolv-retry infinite
ca /etc/openvpn/ca.crt
cert /etc/openvpn/client.crt
key /etc/openvpn/client.key
persist-key
persist-tun
comp-lzo
verb 3
nobind
```
Запускаем
```
root@ubunzuzu:/home/novoselov/test# openvpn --config /etc/openvpn/client.conf
Sun Dec 13 16:41:34 2020 WARNING: file '/etc/openvpn/client.key' is group or others accessible
Sun Dec 13 16:41:34 2020 OpenVPN 2.4.7 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Sep  5 2019
Sun Dec 13 16:41:34 2020 library versions: OpenSSL 1.1.1f  31 Mar 2020, LZO 2.10
Sun Dec 13 16:41:34 2020 WARNING: No server certificate verification method has been enabled.  See http://openvpn.net/howto.html#mitm for more info.
Sun Dec 13 16:41:34 2020 TCP/UDP: Preserving recently used remote address: [AF_INET]127.0.0.1:1194
Sun Dec 13 16:41:34 2020 Socket Buffers: R=[131072->131072] S=[16384->16384]
Sun Dec 13 16:41:34 2020 Attempting to establish TCP connection with [AF_INET]127.0.0.1:1194 [nonblock]
Sun Dec 13 16:41:34 2020 TCP connection established with [AF_INET]127.0.0.1:1194
Sun Dec 13 16:41:34 2020 TCP_CLIENT link local: (not bound)
Sun Dec 13 16:41:34 2020 TCP_CLIENT link remote: [AF_INET]127.0.0.1:1194
Sun Dec 13 16:41:34 2020 TLS: Initial packet from [AF_INET]127.0.0.1:1194, sid=ee7fddf0 05a7b10a
Sun Dec 13 16:41:34 2020 VERIFY OK: depth=1, CN=rasvpn
Sun Dec 13 16:41:34 2020 VERIFY OK: depth=0, CN=rasvpn
Sun Dec 13 16:41:34 2020 Control Channel: TLSv1.2, cipher TLSv1.2 ECDHE-RSA-AES256-GCM-SHA384, 2048 bit RSA
Sun Dec 13 16:41:34 2020 [rasvpn] Peer Connection Initiated with [AF_INET]127.0.0.1:1194
Sun Dec 13 16:41:35 2020 SENT CONTROL [rasvpn]: 'PUSH_REQUEST' (status=1)
Sun Dec 13 16:41:35 2020 PUSH: Received control message: 'PUSH_REPLY,route 10.10.10.0 255.255.255.0,topology net30,ping 10,ping-restart 120,ifconfig 10.10.10.6 10.10.10.5,peer-id 0,cipher AES-256-GCM'
Sun Dec 13 16:41:35 2020 OPTIONS IMPORT: timers and/or timeouts modified
Sun Dec 13 16:41:35 2020 OPTIONS IMPORT: --ifconfig/up options modified
Sun Dec 13 16:41:35 2020 OPTIONS IMPORT: route options modified
Sun Dec 13 16:41:35 2020 OPTIONS IMPORT: peer-id set
Sun Dec 13 16:41:35 2020 OPTIONS IMPORT: adjusting link_mtu to 1627
Sun Dec 13 16:41:35 2020 OPTIONS IMPORT: data channel crypto options modified
Sun Dec 13 16:41:35 2020 Data Channel: using negotiated cipher 'AES-256-GCM'
Sun Dec 13 16:41:35 2020 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Sun Dec 13 16:41:35 2020 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Sun Dec 13 16:41:35 2020 ROUTE_GATEWAY 192.168.88.1/255.255.255.0 IFACE=wlp2s0 HWADDR=f4:96:34:7f:3b:d6
Sun Dec 13 16:41:35 2020 TUN/TAP device tun0 opened
Sun Dec 13 16:41:35 2020 TUN/TAP TX queue length set to 100
Sun Dec 13 16:41:35 2020 /sbin/ip link set dev tun0 up mtu 1500
Sun Dec 13 16:41:35 2020 /sbin/ip addr add dev tun0 local 10.10.10.6 peer 10.10.10.5
Sun Dec 13 16:41:35 2020 /sbin/ip route add 10.10.10.0/24 via 10.10.10.5
Sun Dec 13 16:41:35 2020 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
Sun Dec 13 16:41:35 2020 Initialization Sequence Completed
```

Тестируем доступность
```
novoselov@ubunzuzu:~$ ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.549 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.644 ms
^C
--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1013ms
rtt min/avg/max/mdev = 0.549/0.596/0.644/0.047 ms
```
```
novoselov@ubunzuzu:~$ ip route
default via 192.168.88.1 dev wlp2s0 proto dhcp metric 600 
10.10.10.0/24 via 10.10.10.5 dev tun0 
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6 
169.254.0.0/16 dev wlp2s0 scope link metric 1000 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
192.168.10.0/24 dev vboxnet8 proto kernel scope link src 192.168.10.1 linkdown 
192.168.88.0/24 dev wlp2s0 proto kernel scope link src 192.168.88.14 metric 600 
```

Проверяем доступность с сервера RAS
```
[root@server openvpn]# ping 10.10.10.6
PING 10.10.10.6 (10.10.10.6) 56(84) bytes of data.
64 bytes from 10.10.10.6: icmp_seq=1 ttl=64 time=0.511 ms
64 bytes from 10.10.10.6: icmp_seq=2 ttl=64 time=0.389 ms
```
```
[root@server openvpn]# ip route
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.10.0/24 via 10.10.10.2 dev tun0 
10.10.10.2 dev tun0 proto kernel scope link src 10.10.10.1
```