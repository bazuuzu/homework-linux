Подняли виртуальную машину на CentOS 8.0 из Vagrantfile

## Определить алгоритм с наилучшим сжатием

У ZFS есть встроенное сжатие новых файлов

Устаналиваем zfs
Должны быть установлены yum-utils, epel-release, dkms, wget, lz4
```
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el8_0.noarch.rpm
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
yum-config-manager --enable zfs-kmod
yum-config-manager --disable zfs
yum repolist --enabled | grep zfs && echo ZFS repo enabled
yum install -y zfs
```
```
[root@zfs vagrant]# modprobe zfs
[root@zfs vagrant]# lsmod
Module                  Size  Used by
zfs                  4198400  0
zunicode              335872  1 zfs
zlua                  180224  1 zfs
zcommon                94208  1 zfs
znvpair                90112  2 zfs,zcommon
zavl                   16384  1 zfs
icp                   311296  1 zfs
spl                   122880  5 zfs,icp,znvpair,zcommon,zavl
```
Создадим пул

```
zpool create mypool /dev/sdb
```
Создадим ФС на этом пуле
```
[root@zfs vagrant]# zfs create mypool/gzip
[root@zfs vagrant]# zfs create mypool/lz4
[root@zfs vagrant]# zfs create mypool/gzip9
[root@zfs vagrant]# zfs create mypool/lzjb
[root@zfs vagrant]# zfs list
NAME           USED  AVAIL     REFER  MOUNTPOINT
mypool         210K  9.20G       28K  /mypool
mypool/gzip     24K  9.20G       24K  /mypool/gzip
mypool/gzip9    24K  9.20G       24K  /mypool/gzip9
mypool/lz4      24K  9.20G       24K  /mypool/lz4
mypool/lzjb     24K  9.20G       24K  /mypool/lzjb
```
Качаем "Войну и мир"
```
wget http://www.gutenberg.org/files/2600/2600-0.txt
mv 2600-0.txt War_and_Peace.txt
```
```
[root@zfs vagrant]# ll War_and_Peace.txt 
-rw-r--r--. 1 root root 3359584 Aug  6 14:10 War_and_Peace.txt
```
```
[root@zfs vagrant]# zfs set compression=gzip mypool/gzip
[root@zfs vagrant]# zfs set compression=gzip-9 mypool/gzip9
[root@zfs vagrant]# zfs set compression=lz4 mypool/lz4
[root@zfs vagrant]# zfs set compression=lzjb mypool/lzjb
[root@zfs vagrant]# zfs get compression,compressratio
NAME          PROPERTY       VALUE     SOURCE
mypool        compression    off       default
mypool        compressratio  1.00x     -
mypool/gzip   compression    gzip      local
mypool/gzip   compressratio  1.00x     -
mypool/gzip9  compression    gzip-9    local
mypool/gzip9  compressratio  1.00x     -
mypool/lz4    compression    lz4       local
mypool/lz4    compressratio  1.00x     -
mypool/lzjb   compression    lzjb      local
mypool/lzjb   compressratio  1.00x     -
```
Копируем книгу на наши ФС
```
[root@zfs vagrant]# cp War_and_Peace.txt /mypool/gzip
[root@zfs vagrant]# cp War_and_Peace.txt /mypool/gzip9
[root@zfs vagrant]# cp War_and_Peace.txt /mypool/lz4
[root@zfs vagrant]# cp War_and_Peace.txt /mypool/lzjb/
```
Проверяем
```
[root@zfs vagrant]# zfs get compression,compressratio
NAME          PROPERTY       VALUE     SOURCE
mypool        compression    off       default
mypool        compressratio  1.90x     -
mypool/gzip   compression    gzip      local
mypool/gzip   compressratio  2.67x     -
mypool/gzip9  compression    gzip-9    local
mypool/gzip9  compressratio  2.67x     -
mypool/lz4    compression    lz4       local
mypool/lz4    compressratio  1.62x     -
mypool/lzjb   compression    lzjb      local
mypool/lzjb   compressratio  1.36x     -
```
Наилучшее сжатие у 
```
mypool/gzip   compressratio  2.67x     -
mypool/gzip9  compressratio  2.67x     -
```
Сделал контрольную ФС mypool/compression с простым compression=on и скопировал туда книгу
```
[root@zfs vagrant]# zfs get compression,compressratio
NAME                PROPERTY       VALUE     SOURCE
mypool              compression    off       default
mypool              compressratio  1.84x     -
mypool/compression  compression    on        local
mypool/compression  compressratio  1.62x     -
mypool/gzip         compression    gzip      local
mypool/gzip         compressratio  2.67x     -
mypool/gzip9        compression    gzip-9    local
mypool/gzip9        compressratio  2.67x     -
mypool/lz4          compression    lz4       local
mypool/lz4          compressratio  1.62x     -
mypool/lzjb         compression    lzjb      local
mypool/lzjb         compressratio  1.36x     -
```

## Определить настройки pool’a

Качаем и распаковываем
```
wget -O zfs_task1.tar.gz https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
tar -xvzf zfs_task1.tar.gz
```
```
[root@zfs zpoolexport]# ll
total 1024000
-rw-r--r--. 1 root root 524288000 May 15 05:00 filea
-rw-r--r--. 1 root root 524288000 May 15 05:00 fileb
```
Прикрепляем пул
```
[root@zfs vagrant]# zpool import -d zpoolexport/ otus
[root@zfs vagrant]# zpool list
NAME     SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
mypool  9.50G  9.11M  9.49G        -         -     0%     0%  1.00x    ONLINE  -
otus     480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -
[root@zfs vagrant]# zpool status
  pool: mypool
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        mypool      ONLINE       0     0     0
          sdb       ONLINE       0     0     0

errors: No known data errors

  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
Командами zfs определяем:

- размер хранилища
```
[root@zfs vagrant]# zfs list
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus                2.04M   350M       24K  /otus
otus/hometask2      1.88M   350M     1.88M  /otus/hometask2
[root@zfs vagrant]# zpool list
NAME     SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus     480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -
```
- тип pool (mirror-0)
```
[root@zfs vagrant]# zpool status -v
  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
- значение recordsize
```
[root@zfs vagrant]# zfs get recordsize
NAME                PROPERTY    VALUE    SOURCE
otus                recordsize  128K     local
otus/hometask2      recordsize  128K     inherited from otus
```
- какое сжатие используется
```
[root@zfs vagrant]# zfs get compression,compressratio
NAME                PROPERTY       VALUE     SOURCE
otus                compression    zle       local
otus                compressratio  1.00x     -
otus/hometask2      compression    zle       inherited from otus
otus/hometask2      compressratio  1.00x     -
```
- какая контрольная сумма используется
```
[root@zfs vagrant]# zfs get checksum
NAME                PROPERTY  VALUE      SOURCE
otus                checksum  sha256     local
otus/hometask2      checksum  sha256     inherited from otus
```

## Найти сообщение от преподавателей

Скачаем файл
```
wget -O otus_task2.file https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
```
Создадим ФС otus/storage
```
[root@zfs vagrant]# zfs create otus/storage
[root@zfs vagrant]# zfs list
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus                2.08M   350M       25K  /otus
otus/hometask2      1.88M   350M     1.88M  /otus/hometask2
otus/storage          24K   350M       24K  /otus/storage
```
```
[root@zfs vagrant]# zfs receive otus/storage/task2  < otus_task2.file 
[root@zfs vagrant]# ll /otus/storage/task2/
10M.file           cinderella.tar     for_examaple.txt   homework4.txt      Limbo.txt          Moby_Dick.txt      task1/             War_and_Peace.txt  world.sql
```
Ищем сообщение в файле
```
[root@zfs task2]# find /otus/storage/task2/ -name "*secret_message*"
/otus/storage/task2/task1/file_mess/secret_message
[root@zfs task2]# cat /otus/storage/task2/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```
Сообщение:
```
https://github.com/sindresorhus/awesome
```