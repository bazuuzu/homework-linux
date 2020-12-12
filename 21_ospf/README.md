## Стенд

![hw21.png](https://github.com/bazuuzu/homework-linux/blob/master/21_ospf/hw21.png)

### Часть 1

Смотрим таблицу маршрутизации R1

```
[root@r1 vagrant]# vtysh

Hello, this is Quagga (version 0.99.22.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

r1# sh ip os ro
============ OSPF network routing table ============
N    10.10.1.1/32          [10] area: 0.0.0.0
                           directly attached to lo
N    10.10.2.1/32          [30] area: 0.0.0.0
                           via 10.10.30.2, eth3
N    10.10.3.1/32          [20] area: 0.0.0.0
                           via 10.10.30.2, eth3
N    10.10.10.0/24         [30] area: 0.0.0.0
                           via 10.10.30.2, eth3
N    10.10.20.0/24         [20] area: 0.0.0.0
                           via 10.10.30.2, eth3
N    10.10.30.0/24         [10] area: 0.0.0.0
                           directly attached to eth3

============ OSPF router routing table =============

============ OSPF external routing table ===========
```

Смотрим tcpdump

```
[root@r1 vagrant]# tcpdump -i eth3 icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth3, link-type EN10MB (Ethernet), capture size 262144 bytes
15:22:22.705801 IP 10.10.30.2 > r1: ICMP echo request, id 5930, seq 5, length 64
15:22:22.705872 IP r1 > 10.10.30.2: ICMP echo reply, id 5930, seq 5, length 64
15:22:23.707289 IP 10.10.30.2 > r1: ICMP echo request, id 5930, seq 6, length 64
15:22:23.707352 IP r1 > 10.10.30.2: ICMP echo reply, id 5930, seq 6, length 64
15:22:24.709042 IP 10.10.30.2 > r1: ICMP echo request, id 5930, seq 7, length 64
15:22:24.709101 IP r1 > 10.10.30.2: ICMP echo reply, id 5930, seq 7, length 64
15:22:25.713843 IP 10.10.30.2 > r1: ICMP echo request, id 5930, seq 8, length 64
15:22:25.713910 IP r1 > 10.10.30.2: ICMP echo reply, id 5930, seq 8, length 64
```

Результат: трафик ходит по маршрутам с наименьшим cost - ассиметричный трафик

### Часть 2

Проверка симметричного трафика - отключаем "дешевый" интерфейс

Отключаем eth3 (по дефолту у нас на нем cost 10), трафик должен пойти через eth2 (cost 1000)

```
[root@r1 vagrant]# ip link set eth3 down
[root@r1 vagrant]# tcpdump -i eth2 icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), capture size 262144 bytes
15:25:48.538937 IP 10.10.20.2 > r1: ICMP echo request, id 5932, seq 1, length 64
15:25:48.539029 IP r1 > 10.10.20.2: ICMP echo reply, id 5932, seq 1, length 64
15:25:49.539979 IP 10.10.20.2 > r1: ICMP echo request, id 5932, seq 2, length 64
15:25:49.540036 IP r1 > 10.10.20.2: ICMP echo reply, id 5932, seq 2, length 64
15:25:50.542363 IP 10.10.20.2 > r1: ICMP echo request, id 5932, seq 3, length 64
15:25:50.542443 IP r1 > 10.10.20.2: ICMP echo reply, id 5932, seq 3, length 64
15:25:51.544928 IP 10.10.20.2 > r1: ICMP echo request, id 5932, seq 4, length 64
15:25:51.544991 IP r1 > 10.10.20.2: ICMP echo reply, id 5932, seq 4, length 64
```

Смотрим табл маршрутизации

```
[root@r1 vagrant]# vtysh

Hello, this is Quagga (version 0.99.22.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

r1# sh ip os ro
============ OSPF network routing table ============
N    10.10.1.1/32          [10] area: 0.0.0.0
                           directly attached to lo
N    10.10.2.1/32          [1010] area: 0.0.0.0
                           via 10.10.10.2, eth2
N    10.10.3.1/32          [2010] area: 0.0.0.0
                           via 10.10.10.2, eth2
N    10.10.10.0/24         [1000] area: 0.0.0.0
                           directly attached to eth2
N    10.10.20.0/24         [2000] area: 0.0.0.0
                           via 10.10.10.2, eth2
N    10.10.30.0/24         [3000] area: 0.0.0.0
                           via 10.10.10.2, eth2

============ OSPF router routing table =============

============ OSPF external routing table ===========
```

```
[root@r1 vagrant]# ping 10.10.3.1
PING 10.10.3.1 (10.10.3.1) 56(84) bytes of data.
64 bytes from 10.10.3.1: icmp_seq=1 ttl=63 time=2.00 ms
64 bytes from 10.10.3.1: icmp_seq=2 ttl=63 time=2.13 ms
64 bytes from 10.10.3.1: icmp_seq=3 ttl=63 time=2.04 ms
64 bytes from 10.10.3.1: icmp_seq=4 ttl=63 time=1.87 ms

[root@r1 vagrant]# ping 10.10.2.1
PING 10.10.2.1 (10.10.2.1) 56(84) bytes of data.
64 bytes from 10.10.2.1: icmp_seq=1 ttl=64 time=1.23 ms
64 bytes from 10.10.2.1: icmp_seq=2 ttl=64 time=0.979 ms
64 bytes from 10.10.2.1: icmp_seq=3 ttl=64 time=1.31 ms
64 bytes from 10.10.2.1: icmp_seq=4 ttl=64 time=1.00 ms

[root@r1 vagrant]# ip ro li
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.2.1 via 10.10.10.2 dev eth2 proto zebra metric 1010 
10.10.3.1 via 10.10.10.2 dev eth2 proto zebra metric 2010 
10.10.10.0/24 dev eth2 proto kernel scope link src 10.10.10.1 metric 102 
10.10.20.0/24 via 10.10.10.2 dev eth2 proto zebra metric 2000 
10.10.30.0/24 via 10.10.10.2 dev eth2 proto zebra metric 3000 
172.20.10.0/24 dev eth1 proto kernel scope link src 172.20.10.10 metric 101 
```

Мы проверили доступность через "дорогой маршрут"

Возвращаем все на место и проверяем

```
[root@r1 vagrant]# ip link set eth3 up         
[root@r1 vagrant]# ip ro li
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.2.1 via 10.10.10.2 dev eth2 proto zebra metric 1010 
10.10.3.1 via 10.10.10.2 dev eth2 proto zebra metric 2010 
10.10.10.0/24 dev eth2 proto kernel scope link src 10.10.10.1 metric 102 
10.10.20.0/24 via 10.10.10.2 dev eth2 proto zebra metric 2000 
10.10.30.0/24 dev eth3 proto kernel scope link src 10.10.30.1 metric 103 
172.20.10.0/24 dev eth1 proto kernel scope link src 172.20.10.10 metric 101 
```