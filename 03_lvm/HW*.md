## Ставим btrfs, так как ZFS будет разбираться на следующих занятиях

Проверяем блочные устройста

```shell
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Устанавливаем ФС на 1 диске и на двух дисках, посмотрим различия
На 1 диске
```shell
[root@lvm vagrant]# mkfs.btrfs /dev/sdb
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               16084b57-91d7-427e-a9bd-ac26cf45957d
Node size:          16384
Sector size:        4096
Filesystem size:    10.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP               1.00GiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    10.00GiB  /dev/sdb
```

Данные хранятся в режиме single
Метаданные и system хранятся в режиме DUP - дублирование на 1 диске. Т.е. под данные остаётся 10 - 1*2Gib

Сделаем ФС на двух устроствах
```shell
[root@lvm vagrant]# mkfs.btrfs /dev/sdc /dev/sdd
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               85c1c59d-c49d-4c46-b5f4-df05b08279b9
Node size:          16384
Sector size:        4096
Filesystem size:    3.00GiB
Block group profiles:
  Data:             RAID0           307.12MiB
  Metadata:         RAID1           153.56MiB
  System:           RAID1             8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  2
Devices:
   ID        SIZE  PATH
    1     2.00GiB  /dev/sdc
    2     1.00GiB  /dev/sdd
```
Видим, что данные будут записываться в RAID0, а метаданные на RAID1



Проверяем, что там BTRFS
```shell
[root@lvm vagrant]# file -s /dev/sd{b,c,d}
/dev/sdb: BTRFS Filesystem sectorsize 4096, nodesize 16384, leafsize 16384)
/dev/sdc: BTRFS Filesystem sectorsize 4096, nodesize 16384, leafsize 16384)
/dev/sdd: BTRFS Filesystem sectorsize 4096, nodesize 16384, leafsize 16384)
```

Монтируем
```shell
[root@lvm vagrant]# mkdir /mnt/sdb
[root@lvm vagrant]# mount /dev/sdb /mnt/sdb/
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  742M   37G   2% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
/dev/sdb                        btrfs      10G   17M  8.0G   1% /mnt/sdb
```
Видим появившийся раздел с доступными 8G

Сканируем устройства и показываем файловые системы btrfs
```shell
[root@lvm vagrant]# btrfs device scan
Scanning for Btrfs filesystems
[root@lvm vagrant]# btrfs filesystem show
Label: none  uuid: 16084b57-91d7-427e-a9bd-ac26cf45957d
	Total devices 1 FS bytes used 384.00KiB
	devid    1 size 10.00GiB used 2.02GiB path /dev/sdb

Label: none  uuid: 85c1c59d-c49d-4c46-b5f4-df05b08279b9
	Total devices 2 FS bytes used 112.00KiB
	devid    1 size 2.00GiB used 315.12MiB path /dev/sdc
	devid    2 size 1.00GiB used 315.12MiB path /dev/sdd

```
Монтируем ФС из двух btrfs
Когда из двух устройст, достаточно указать любое из этих устройст. Монтироваться всегда будет первый по алфавиту
```shell
[root@lvm vagrant]# mkdir /mnt/sdc-d
[root@lvm vagrant]# mount /dev/sdc /mnt/sdc-d/
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  741M   37G   2% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
/dev/sdb                        btrfs      10G   17M  8.0G   1% /mnt/sdb
/dev/sdc                        btrfs     3.0G   17M  1.7G   1% /mnt/sdc-d
```

## Переносим каталог /opt на том с btrfs

```shell
[root@lvm vagrant]# mount /dev/sdb /opt
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk /opt
sdc                       8:32   0    2G  0 disk /mnt/sdc-d
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
Правим /etc/fstab
```shell
[root@lvm vagrant]# btrfs device scan
Scanning for Btrfs filesystems
[root@lvm vagrant]# btrfs filesystem show
Label: none  uuid: 16084b57-91d7-427e-a9bd-ac26cf45957d
	Total devices 1 FS bytes used 384.00KiB
	devid    1 size 10.00GiB used 2.02GiB path /dev/sdb

Label: none  uuid: 85c1c59d-c49d-4c46-b5f4-df05b08279b9
	Total devices 2 FS bytes used 256.00KiB
	devid    1 size 2.00GiB used 315.12MiB path /dev/sdc
	devid    2 size 1.00GiB used 315.12MiB path /dev/sdd
```
```shell
[root@lvm vagrant]# btrfs filesystem show >> /etc/fstab 
[root@lvm vagrant]# nano /etc/fstab 
```
```shell
UUID=16084b57-91d7-427e-a9bd-ac26cf45957d	/opt        btrfs   defaults 0 0

UUID=85c1c59d-c49d-4c46-b5f4-df05b08279b9	/mnt/sdc-d	btrfs   device=/dev/sdc,device=/dev/sdd 0 0
```
Делаем umount и монитруем из fstab командой mount -a
```shell
[root@lvm vagrant]# umount /mnt/sdc-d/
[root@lvm vagrant]# umount /mnt/sdb/
[root@lvm vagrant]# umount /opt/
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  743M   37G   2% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
[root@lvm vagrant]# mount -a
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  743M   37G   2% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
/dev/sdb                        btrfs      10G   17M  8.0G   1% /opt
/dev/sdc                        btrfs     3.0G   17M  1.7G   1% /mnt/sdc-d
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk /opt
sdc                       8:32   0    2G  0 disk /mnt/sdc-d

```
Создадим файлов
```shell
[root@lvm vagrant]# touch /opt/file{1..20}
[root@lvm vagrant]# ls /opt
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9
```

## Изменим размер BTRFS

Создадим на sde btrfs
```shell
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  743M   37G   2% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
/dev/sdb                        btrfs      10G   17M  8.0G   1% /opt
/dev/sdc                        btrfs     3.0G   17M  1.7G   1% /mnt/sdc-d
[root@lvm vagrant]# mkfs.btrfs /dev/sde
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               b6006077-df50-45e8-b22f-879faab097ba
Node size:          16384
Sector size:        4096
Filesystem size:    1.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP              51.19MiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1     1.00GiB  /dev/sde
```
Добавим sde к уже смонтированному в папке /opt
```shell
[root@lvm vagrant]# btrfs device add -f /dev/sde /opt
[root@lvm vagrant]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  743M   37G   2% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
/dev/sdb                        btrfs      11G   17M  9.0G   1% /opt
/dev/sdc                        btrfs     3.0G   17M  1.7G   1% /mnt/sdc-d
```

## Cнапшоты

Создаём подраздел
```shell
[root@lvm sub_vlm]# btrfs subvolume create /mnt/sdc-d/subvlm0
Create subvolume '/mnt/sdc-d/subvlm0'
[root@lvm subvlm1]# btrfs subvolume create /mnt/sdc-d/subvlm2
Create subvolume '/mnt/sdc-d/subvlm2'
```
```shell
[root@lvm subvlm0]# btrfs subvolume list /mnt/sdc-d/
ID 262 gen 21 top level 5 path subvlm0
ID 263 gen 20 top level 5 path subvlm2
```
Создаём в /mnt/sdc-d/subvlm0 файлы
```shell
[root@lvm subvlm1]# cd /mnt/sdc-d/subvlm0
[root@lvm subvlm0]# ls
[root@lvm subvlm0]# touch file{1..20}
[root@lvm subvlm0]# ls
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9
```


Делаем снапшот с "/mnt/sdc-d/subvlm0/" в "/mnt/sdc-d/subvlm2/"
```shell
[root@lvm subvlm0]# btrfs subvolume snapshot /mnt/sdc-d/subvlm0/ /mnt/sdc-d/subvlm2/
Create a snapshot of '/mnt/sdc-d/subvlm0/' in '/mnt/sdc-d/subvlm2//subvlm0'
```
Проверяем файлы
```shell
[root@lvm subvlm0]# ls -lh /mnt/sdc-d/subvlm2/subvlm0/
total 0
-rw-r--r--. 1 root root 0 Aug 15 19:40 file1
-rw-r--r--. 1 root root 0 Aug 15 19:40 file10
-rw-r--r--. 1 root root 0 Aug 15 19:40 file11
-rw-r--r--. 1 root root 0 Aug 15 19:40 file12
-rw-r--r--. 1 root root 0 Aug 15 19:40 file13
-rw-r--r--. 1 root root 0 Aug 15 19:40 file14
-rw-r--r--. 1 root root 0 Aug 15 19:40 file15
-rw-r--r--. 1 root root 0 Aug 15 19:40 file16
-rw-r--r--. 1 root root 0 Aug 15 19:40 file17
-rw-r--r--. 1 root root 0 Aug 15 19:40 file18
-rw-r--r--. 1 root root 0 Aug 15 19:40 file19
-rw-r--r--. 1 root root 0 Aug 15 19:40 file2
-rw-r--r--. 1 root root 0 Aug 15 19:40 file20
-rw-r--r--. 1 root root 0 Aug 15 19:40 file3
-rw-r--r--. 1 root root 0 Aug 15 19:40 file4
-rw-r--r--. 1 root root 0 Aug 15 19:40 file5
-rw-r--r--. 1 root root 0 Aug 15 19:40 file6
-rw-r--r--. 1 root root 0 Aug 15 19:40 file7
-rw-r--r--. 1 root root 0 Aug 15 19:40 file8
-rw-r--r--. 1 root root 0 Aug 15 19:40 file9

```
Удалим несколько файлов
```shell
[root@lvm subvlm0]# rm -rf /mnt/sdc-d/subvlm0/file{1..10}
[root@lvm subvlm0]# ls -lh /mnt/sdc-d/subvlm0
total 0
-rw-r--r--. 1 root root 0 Aug 15 19:40 file11
-rw-r--r--. 1 root root 0 Aug 15 19:40 file12
-rw-r--r--. 1 root root 0 Aug 15 19:40 file13
-rw-r--r--. 1 root root 0 Aug 15 19:40 file14
-rw-r--r--. 1 root root 0 Aug 15 19:40 file15
-rw-r--r--. 1 root root 0 Aug 15 19:40 file16
-rw-r--r--. 1 root root 0 Aug 15 19:40 file17
-rw-r--r--. 1 root root 0 Aug 15 19:40 file18
-rw-r--r--. 1 root root 0 Aug 15 19:40 file19
-rw-r--r--. 1 root root 0 Aug 15 19:40 file20

```
Восстанавливаем из снапшота
```shell
[root@lvm subvlm0]# btrfs subvolume snapshot /mnt/sdc-d/subvlm2/subvlm0/ /mnt/sdc-d/subvlm0
Create a snapshot of '/mnt/sdc-d/subvlm2/subvlm0/' in '/mnt/sdc-d/subvlm0/subvlm0'
[root@lvm subvlm0]# ls -lh /mnt/sdc-d/subvlm0/subvlm0
total 0
-rw-r--r--. 1 root root 0 Aug 15 19:40 file1
-rw-r--r--. 1 root root 0 Aug 15 19:40 file10
-rw-r--r--. 1 root root 0 Aug 15 19:40 file11
-rw-r--r--. 1 root root 0 Aug 15 19:40 file12
-rw-r--r--. 1 root root 0 Aug 15 19:40 file13
-rw-r--r--. 1 root root 0 Aug 15 19:40 file14
-rw-r--r--. 1 root root 0 Aug 15 19:40 file15
-rw-r--r--. 1 root root 0 Aug 15 19:40 file16
-rw-r--r--. 1 root root 0 Aug 15 19:40 file17
-rw-r--r--. 1 root root 0 Aug 15 19:40 file18
-rw-r--r--. 1 root root 0 Aug 15 19:40 file19
-rw-r--r--. 1 root root 0 Aug 15 19:40 file2
-rw-r--r--. 1 root root 0 Aug 15 19:40 file20
-rw-r--r--. 1 root root 0 Aug 15 19:40 file3
-rw-r--r--. 1 root root 0 Aug 15 19:40 file4
-rw-r--r--. 1 root root 0 Aug 15 19:40 file5
-rw-r--r--. 1 root root 0 Aug 15 19:40 file6
-rw-r--r--. 1 root root 0 Aug 15 19:40 file7
-rw-r--r--. 1 root root 0 Aug 15 19:40 file8
-rw-r--r--. 1 root root 0 Aug 15 19:40 file9
```
