Строим бонды и вланы<br>
в Office1 в тестовой подсети появляется сервера с доп интерфесами и адресами<br>
в internal сети testLAN<br>
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1
- testServer2- 10.10.10.1

равести вланами<br>
testClient1 <-> testServer1<br>
testClient2 <-> testServer2<br>

между centralRouter и inetRouter<br>
"пробросить" 2 линка (общая inernal сеть) и объединить их в бонд<br>
проверить работу c отключением интерфейсов<br>


### Проверим VLAN's

Схема <br>
![vlan_otus.png](https://github.com/bazuuzu/homework-linux/blob/master/24_vlan/vlan_otus.png)
<br>

testServer1:
```
[root@testServer1 vagrant]# ip --brief link show
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0             UP             52:54:00:4d:77:d3 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1             UP             08:00:27:e9:5e:d2 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth2             UP             08:00:27:bc:fd:1e <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1.10@eth1     UP             08:00:27:e9:5e:d2 <BROADCAST,MULTICAST,UP,LOWER_UP> 
[root@testServer1 vagrant]# ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.2/24 fe80::a00:27ff:fee9:5ed2/64 
eth2             UP             10.11.11.111/24 fe80::a00:27ff:febc:fd1e/64 
eth1.10@eth1     UP             10.10.10.1/24 fe80::a00:27ff:fee9:5ed2/64 
[root@testServer1 vagrant]# ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=1.06 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.499 ms
```

testClient1:
```
[root@testClient1 vagrant]# ip --brief link show
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0             UP             52:54:00:4d:77:d3 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1             UP             08:00:27:08:88:33 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth2             UP             08:00:27:f8:e6:49 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1.10@eth1     UP             08:00:27:08:88:33 <BROADCAST,MULTICAST,UP,LOWER_UP> 
[root@testClient1 vagrant]# ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.3/24 fe80::a00:27ff:fe08:8833/64 
eth2             UP             10.11.11.121/24 fe80::a00:27ff:fef8:e649/64 
eth1.10@eth1     UP             10.10.10.254/24 fe80::a00:27ff:fe08:8833/64 
[root@testClient1 vagrant]# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.384 ms
```

testServer2:
```
[vagrant@testServer2 ~]$ ip --brief link show
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0             UP             52:54:00:4d:77:d3 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1             UP             08:00:27:51:43:d0 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth2             UP             08:00:27:f4:00:8d <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1.20@eth1     UP             08:00:27:51:43:d0 <BROADCAST,MULTICAST,UP,LOWER_UP> 
[vagrant@testServer2 ~]$ ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.4/24 fe80::a00:27ff:fe51:43d0/64 
eth2             UP             10.11.11.112/24 fe80::a00:27ff:fef4:8d/64 
eth1.20@eth1     UP             10.10.10.1/24 fe80::a00:27ff:fe51:43d0/64 
[vagrant@testServer2 ~]$ ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.946 ms
```

testClient2:
```
[root@testClient2 vagrant]# ip --brief link show
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0             UP             52:54:00:4d:77:d3 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1             UP             08:00:27:43:b0:bf <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth2             UP             08:00:27:5f:56:2f <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1.20@eth1     UP             08:00:27:43:b0:bf <BROADCAST,MULTICAST,UP,LOWER_UP> 
[root@testClient2 vagrant]# ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.5/24 fe80::a00:27ff:fe43:b0bf/64 
eth2             UP             10.11.11.122/24 fe80::a00:27ff:fe5f:562f/64 
eth1.20@eth1     UP             10.10.10.254/24 fe80::a00:27ff:fe43:b0bf/64 
[root@testClient2 vagrant]# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.324 ms
```

### Проверка bonding между роутерами и отказоустойчивость линка

inetRouter:
```
[root@inetRouter vagrant]# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:6a:68:a9
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:f9:26:9b
Slave queue ID: 0
```
```
[root@inetRouter vagrant]# cat /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
NAME=bond0
TYPE=Bond
BONDING_MASTER=yes
IPADDR=10.1.1.1
NETMASK=255.255.255.252
ONBOOT=yes
USERCTL=no
BOOTPROTO=static
BONDING_OPTS="mode=1 miimon=100 fail_over_mac=1"
ZONE=internal[root@inetRouter vagrant]# 
```
На CentralRouter:
```
[root@centralRouter vagrant]# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:c3:d4:d3
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:8e:d7:0c
Slave queue ID: 0
```
```
[root@centralRouter vagrant]# cat /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
NAME=bond0
TYPE=Bond
BONDING_MASTER=yes
IPADDR=10.1.1.2
NETMASK=255.255.255.252
ONBOOT=yes
USERCTL=no
BOOTPROTO=static
BONDING_OPTS="mode=1 miimon=100 fail_over_mac=1"
GATEWAY=10.1.1.1 
```
Ставим пинг и отключаем интерфейс eth1 на inetRouter
```
[root@inetRouter vagrant]# ip link set eth1 down
[root@inetRouter vagrant]# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth2
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: down
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 1
Permanent HW addr: 08:00:27:6a:68:a9
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:f9:26:9b
Slave queue ID: 0
```
В это время пинги:
```
[root@inetRouter vagrant]# ping 10.1.1.2
PING 10.1.1.2 (10.1.1.2) 56(84) bytes of data.
64 bytes from 10.1.1.2: icmp_seq=1 ttl=64 time=0.525 ms
64 bytes from 10.1.1.2: icmp_seq=2 ttl=64 time=0.812 ms
64 bytes from 10.1.1.2: icmp_seq=3 ttl=64 time=0.433 ms
64 bytes from 10.1.1.2: icmp_seq=4 ttl=64 time=0.582 ms
64 bytes from 10.1.1.2: icmp_seq=5 ttl=64 time=0.529 ms
64 bytes from 10.1.1.2: icmp_seq=6 ttl=64 time=0.307 ms
64 bytes from 10.1.1.2: icmp_seq=7 ttl=64 time=0.425 ms
64 bytes from 10.1.1.2: icmp_seq=8 ttl=64 time=0.423 ms
64 bytes from 10.1.1.2: icmp_seq=9 ttl=64 time=0.790 ms
64 bytes from 10.1.1.2: icmp_seq=10 ttl=64 time=0.531 ms
64 bytes from 10.1.1.2: icmp_seq=11 ttl=64 time=0.495 ms
64 bytes from 10.1.1.2: icmp_seq=12 ttl=64 time=0.501 ms
64 bytes from 10.1.1.2: icmp_seq=13 ttl=64 time=0.371 ms
64 bytes from 10.1.1.2: icmp_seq=14 ttl=64 time=0.354 ms
64 bytes from 10.1.1.2: icmp_seq=15 ttl=64 time=0.588 ms
64 bytes from 10.1.1.2: icmp_seq=16 ttl=64 time=0.352 ms
64 bytes from 10.1.1.2: icmp_seq=17 ttl=64 time=0.388 ms
64 bytes from 10.1.1.2: icmp_seq=18 ttl=64 time=0.401 ms
64 bytes from 10.1.1.2: icmp_seq=19 ttl=64 time=0.320 ms
64 bytes from 10.1.1.2: icmp_seq=20 ttl=64 time=0.419 ms
64 bytes from 10.1.1.2: icmp_seq=21 ttl=64 time=0.408 ms
64 bytes from 10.1.1.2: icmp_seq=22 ttl=64 time=0.470 ms
```
Как видим: потерь пакетов не было