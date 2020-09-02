## Размер хранилища
```
[root@zfs vagrant]# zfs list
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus                2.04M   350M       24K  /otus
otus/hometask2      1.88M   350M     1.88M  /otus/hometask2
[root@zfs vagrant]# zpool list
NAME     SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus     480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -
```
## Тип pool (mirror-0)
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
## Значение recordsize
```
[root@zfs vagrant]# zfs get recordsize
NAME                PROPERTY    VALUE    SOURCE
otus                recordsize  128K     local
otus/hometask2      recordsize  128K     inherited from otus
```
## Какое сжатие используется
```
[root@zfs vagrant]# zfs get compression,compressratio
NAME                PROPERTY       VALUE     SOURCE
otus                compression    zle       local
otus                compressratio  1.00x     -
otus/hometask2      compression    zle       inherited from otus
otus/hometask2      compressratio  1.00x     -
```
## Какая контрольная сумма используется
```
[root@zfs vagrant]# zfs get checksum
NAME                PROPERTY  VALUE      SOURCE
otus                checksum  sha256     local
otus/hometask2      checksum  sha256     inherited from otus
```