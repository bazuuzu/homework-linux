# Теоретическая часть

### Office 1

192.168.2.0/26 - dev - HostMin:	192.168.2.1 - HostMax:	192.168.2.62 - Broadcast:	192.168.2.63<br>
192.168.2.64/26 - test servers - HostMin:	192.168.2.65 - HostMax:	192.168.2.126 - Broadcast:	192.168.2.127<br>
192.168.2.128/26 - managers - HostMin:	192.168.2.129 - HostMax:	192.168.2.190 - Broadcast:	192.168.2.191<br>
192.168.2.192/26 - office hardware - HostMin:	192.168.2.193 - HostMax:	192.168.2.254 - Broadcast:	192.168.2.255<br>

### Office 2

192.168.1.0/25 - dev - HostMin:	192.168.1.1 - HostMax:	192.168.1.126 - Broadcast:	192.168.1.127
192.168.1.128/26 - test servers - HostMin:	192.168.1.129 - HostMax:	192.168.1.190 - Broadcast:	192.168.1.191
192.168.1.192/26 - office hardware - HostMin:	192.168.1.193 - HostMax:	192.168.1.254 - Broadcast:	192.168.1.255

### Central

192.168.0.0/28 - directors - HostMin:	192.168.0.1 - HostMax:	192.168.0.14 - Broadcast:	192.168.0.15<br>
**192.168.0.16/28 - another network - HostMin:	192.168.0.17 - HostMax:	192.168.0.30 - Broadcast:	192.168.0.31 - FREE SUBNET<br>**
192.168.0.32/28 - office hardware - HostMin:	192.168.0.33 - HostMax:	192.168.0.46 - Broadcast:	192.168.0.47<br>
**192.168.0.48/28 - another network - HostMin:	192.168.0.49 - HostMax:	192.168.0.62 - Broadcast:	192.168.0.63 - FREE SUBNET<br>**
192.168.0.64/26 - wifi - HostMin:	192.168.0.65 - HostMax:	192.168.0.126 - Broadcast:	192.168.0.127<br>
**192.168.0.128/25 - another network - HostMin:	192.168.0.129 - HostMax:	192.168.0.254 - Broadcast:	192.168.0.255 - FREE SUBNET<br>**

# Практическая часть

Схема <br>
![schema.png](https://github.com/bazuuzu/homework-linux/blob/master/17_network/schema.png)

Для проверки склонировать репозиторий и запустить Vagrantfile и попинговать другие хосты с, допустим, off1Server