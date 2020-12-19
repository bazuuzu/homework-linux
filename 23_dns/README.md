# Vagrant DNS Lab

A Bind's DNS lab with Vagrant and Ansible, based on CentOS 7.

# Playground

<code>
    vagrant ssh client
</code>

  * zones: dns.lab, reverse dns.lab and ddns.lab
  * ns01 (192.168.50.10)
    * master, recursive, allows update to ddns.lab
  * ns02 (192.168.50.11)
    * slave, recursive
  * client (192.168.50.15)
    * used to test the env, runs rndc and nsupdate
  * client2 (192.168.50.16)
    * used to test the env, runs rndc and nsupdate
  * zone transfer: TSIG key

```
завести в зоне dns.lab
имена
web1 - смотрит на клиент1
web2 смотрит на клиент2
```

/etc/named/named.dns.lab - сюда дописываем, в файл зоны

```
; A records
@               IN      A       192.168.50.10
@               IN      A       192.168.50.11
web1            IN      A       192.168.50.15
web2            IN      A       192.168.50.16
```

```
[root@client ~]# nslookup web1.dns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   web1.dns.lab
Address: 192.168.50.15

[root@client ~]# nslookup web2.dns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   web2.dns.lab
Address: 192.168.50.16
```

### Завести ещё одну зону newdns.lab

```
завести еще одну зону newdns.lab
завести в ней запись
www - смотрит на обоих клиентов
```

Добавляем файл named.newdns.lab в /etc/named/
```
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.newdns.lab. root.newdns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.newdns.lab.
                IN      NS      ns02.newdns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

; A records
@               IN      A       192.168.50.10
@               IN      A       192.168.50.11
www             IN      A       192.168.50.15
www             IN      A       192.168.50.16
```

В файл /etc/named.conf
```
// lab's zone
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
};
```

Перезапустили named, проверяем:
```
[root@client ~]# nslookup www.newdns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   www.newdns.lab
Address: 192.168.50.15
Name:   www.newdns.lab
Address: 192.168.50.16
```

### Настроить split-dns

```
настроить split-dns
клиент1 - видит обе зоны, но в зоне dns.lab только web1
клиент2 видит только dns.lab

```

```
[root@client ~]# dnssec-keygen -a HMAC-MD5 -b 128 -n HOST client1-key | base64
S2NsaWVudDEta2V5LisxNTcrNTExMTkK

[root@client vagrant]# dnssec-keygen -a HMAC-MD5 -b 128 -n HOST client2-key | base64
S2NsaWVudDIta2V5LisxNTcrNDQzNjIK
```

### Проверка

Проверяем с client:
```
[root@client vagrant]# nslookup dns.lab 192.168.50.11
Server:         192.168.50.11
Address:        192.168.50.11#53

Name:   dns.lab
Address: 192.168.50.11
Name:   dns.lab
Address: 192.168.50.10

[root@client vagrant]# nslookup dns.lab 192.168.50.10
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   dns.lab
Address: 192.168.50.10
Name:   dns.lab
Address: 192.168.50.11

[root@client vagrant]# nslookup web1.dns.lab 192.168.50.10
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   web1.dns.lab
Address: 192.168.50.15

[root@client vagrant]# nslookup web1.dns.lab 192.168.50.11
Server:         192.168.50.11
Address:        192.168.50.11#53

Name:   web1.dns.lab
Address: 192.168.50.15

[root@client vagrant]# nslookup web2.dns.lab 192.168.50.11
Server:         192.168.50.11
Address:        192.168.50.11#53

** server can't find web2.dns.lab: NXDOMAIN

[root@client vagrant]# nslookup web2.dns.lab 192.168.50.10
Server:         192.168.50.10
Address:        192.168.50.10#53

** server can't find web2.dns.lab: NXDOMAIN

[root@client vagrant]# nslookup newdns.lab 192.168.50.10
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   newdns.lab
Address: 192.168.50.11
Name:   newdns.lab
Address: 192.168.50.10

[root@client vagrant]# nslookup newdns.lab 192.168.50.11
Server:         192.168.50.11
Address:        192.168.50.11#53

Name:   newdns.lab
Address: 192.168.50.11
Name:   newdns.lab
Address: 192.168.50.10

[root@client vagrant]# nslookup www.newdns.lab 192.168.50.10
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   www.newdns.lab
Address: 192.168.50.16
Name:   www.newdns.lab
Address: 192.168.50.15

[root@client vagrant]# nslookup www.newdns.lab 192.168.50.11
Server:         192.168.50.11
Address:        192.168.50.11#53

Name:   www.newdns.lab
Address: 192.168.50.16
Name:   www.newdns.lab
Address: 192.168.50.15
```

Проверяем на client2:
```
[root@client2 vagrant]# nslookup dns.lab 192.168.50.10
Server:		192.168.50.10
Address:	192.168.50.10#53

Name:	dns.lab
Address: 192.168.50.10
Name:	dns.lab
Address: 192.168.50.11

[root@client2 vagrant]# nslookup dns.lab 192.168.50.11
Server:		192.168.50.11
Address:	192.168.50.11#53

Name:	dns.lab
Address: 192.168.50.10
Name:	dns.lab
Address: 192.168.50.11

[root@client2 vagrant]# nslookup web1.dns.lab 192.168.50.10
Server:		192.168.50.10
Address:	192.168.50.10#53

Name:	web1.dns.lab
Address: 192.168.50.15

[root@client2 vagrant]# nslookup web1.dns.lab 192.168.50.11
Server:		192.168.50.11
Address:	192.168.50.11#53

Name:	web1.dns.lab
Address: 192.168.50.15

[root@client2 vagrant]# nslookup web2.dns.lab 192.168.50.10
Server:		192.168.50.10
Address:	192.168.50.10#53

Name:	web2.dns.lab
Address: 192.168.50.16

[root@client2 vagrant]# nslookup web2.dns.lab 192.168.50.11
Server:		192.168.50.11
Address:	192.168.50.11#53

Name:	web2.dns.lab
Address: 192.168.50.16

[root@client2 vagrant]# nslookup newdns.lab 192.168.50.10
Server:		192.168.50.10
Address:	192.168.50.10#53

** server can't find newdns.lab: NXDOMAIN

[root@client2 vagrant]# nslookup newdns.lab 192.168.50.11
Server:		192.168.50.11
Address:	192.168.50.11#53

** server can't find newdns.lab: NXDOMAIN

[root@client2 vagrant]# nslookup www.newdns.lab 192.168.50.10
Server:		192.168.50.10
Address:	192.168.50.10#53

** server can't find www.newdns.lab: NXDOMAIN

[root@client2 vagrant]# nslookup www.newdns.lab 192.168.50.11
Server:		192.168.50.11
Address:	192.168.50.11#53

** server can't find www.newdns.lab: NXDOMAIN
```