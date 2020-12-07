### 1) реализовать knocking port

На inetRouter меняем конфиг sshd:
```
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service
```



Последовательность портов будет такая: 8881 7777 9991

Создаём правило на сервере. Записываем его в файл iptables.rules:

```
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:TRAFFIC - [0:0]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]
-A INPUT -j TRAFFIC
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i eth1 -j ACCEPT
-A TRAFFIC -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 -j ACCEPT
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp -m recent --name SSH2 --remove -j DROP
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp --dport 9991 -m recent --rcheck --name SSH1 -j SSH-INPUTTWO
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp -m recent --name SSH1 --remove -j DROP
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp --dport 7777 -m recent --rcheck --name SSH0 -j SSH-INPUT
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp -m recent --name SSH0 --remove -j DROP
-A TRAFFIC -m conntrack --ctstate NEW -m tcp -p tcp --dport 8881 -m recent --name SSH0 --set -j DROP
-A SSH-INPUT -m recent --name SSH1 --set -j DROP
-A SSH-INPUTTWO -m recent --name SSH2 --set -j DROP
-A TRAFFIC -j DROP
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o eth0 -j MASQUERADE
COMMIT
```

systemctl start iptables
systemctl enable iptables
iptables-restore < iptables.rules
service iptables save

на CantralRouter:

yum install -y nmap

```
#!/bin/bash
HOST=$1
shift
for ARG in "$@"
do
        sudo nmap -Pn --max-retries 0 -p $ARG $HOST
done
```
```
[root@centralRouter vagrant]# ./knock.sh 192.168.255.1 8881 7777 9991

Starting Nmap 6.40 ( http://nmap.org ) at 2020-12-07 12:38 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00046s latency).
PORT     STATE    SERVICE
8881/tcp filtered unknown
MAC Address: 08:00:27:BB:91:37 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.39 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2020-12-07 12:38 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00037s latency).
PORT     STATE    SERVICE
7777/tcp filtered cbt
MAC Address: 08:00:27:BB:91:37 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.35 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2020-12-07 12:38 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00037s latency).
PORT     STATE    SERVICE
9991/tcp filtered issa
MAC Address: 08:00:27:BB:91:37 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.37 seconds
```
Пробуем подключиться под пользователем vagrant с паролем vagrant:
```
[root@centralRouter vagrant]# ssh vagrant@192.168.255.1
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ECDSA key fingerprint is SHA256:rv05EzdhoyNuCpuxNQq3WZLWKJbB3OwpO0tlsLQ5uqM.
ECDSA key fingerprint is MD5:1e:19:04:20:7a:ed:b2:9d:4a:79:86:ab:c3:93:26:dc.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.255.1' (ECDSA) to the list of known hosts.
vagrant@192.168.255.1's password: 
[vagrant@inetRouter ~]$ 
```

Все успешно подключилось. Теперь пробуем подключиться без простукивания:
```
[root@centralRouter vagrant]# ssh vagrant@192.168.255.1
ssh: connect to host 192.168.255.1 port 22: Connection timed out
```
Не смог подключиться, случился timeout на подключение

### 2) добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост

### 3) запустить nginx на centralServer

Здесь случилась проблема