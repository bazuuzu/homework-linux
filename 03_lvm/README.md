Устанавливаем xfsdump, он будет нужен для снятия копии / тома
```shell
yum install xfsdump nano -y
```
Смотрим, какие есть блочные устройства: lsblk
```
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

## Уменьшить том под / до 8G

Подготовим временный том для / раздела:
```shell
pvcreate /dev/sdb
```
```shell
vgcreate vg_root /dev/sdb
```
```shell
lvcreate -n lv_root -l +100%FREE /dev/vg_root
```

Создаём на нём файловую систему и смонтируем, чтобы перенести туда данные

```shell
[root@lvm vagrant]# mkfs.xfs /dev/vg_root/lv_root
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```
```shell
mount /dev/vg_root/lv_root /mnt
```

Этой командой скопируем все даннýе с / раздела в /mnt:

```shell
[root@lvm vagrant]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
Получили вывод:
```shell
xfsrestore: Restore Status: SUCCESS
```

Проверяем, что скопировалось
```shell
[root@lvm vagrant]# ls /mnt
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  vagrant  var

```
Переконфигурируем GRUB, чтобы при старте перейти в новый /

Сымитируем текущий root -> сделаем в него chroot и обновим grub

```shell
[root@lvm vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm vagrant]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

Обновим образ initrd

```shell
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```

Для того, чтобы при загрузке был смонтирован нужный root нужно в файле
```shell
/boot/grub2/grub.cfg заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root
```
```shell
nano /boot/grub2/grub.cfg
```

Перезагружаемся и проверяем

```shell
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удалāем
старый LV размеров в 40G и создаем новый на 8G:
```shell
[root@lvm vagrant]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```
```shell
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

Проделываем на нем те же операции, что и в первый раз:
```shell
mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
```

Так же как в первый раз переконфигурируем grub, за исключением правки /etc/grub2/grub.cfg

```shell
[root@lvm vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm vagrant]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```
```shell
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
```
```shell
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Пока не перезагружаемся и не выходим из под chroot - мы можем заодно перенести /var

## Выделить том под /var в зеркало

На свободных дисках создаем зеркало:

```shell
[root@lvm boot]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
```
```shell
[root@lvm boot]# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
```
```shell
[root@lvm boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```

Создаем на нем ФС и перемещаем туда /var:

```shell
[root@lvm boot]# mkfs.ext4 /dev/vg_var/lv_var
Writing superblocks and filesystem accounting information: done
```
```shell
mount /dev/vg_var/lv_var /mnt
```
```shell
cp -aR /var/* /mnt/ # rsync -avHPSAX /var/ /mnt/
```

На всякий случай сохранāем содержимое старого var (или же можно его просто удалить)
```shell
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```

Монтируем новый var в каталог /var
```shell
[root@lvm boot]# umount /mnt
[root@lvm boot]# mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:
```shell
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

Перезагружаемся в новый root и удаляем временную Volume Group
```shell
[vagrant@lvm ~]$ sudo lvremove /dev/vg_root/lv_root
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
```
```shell
[root@lvm vagrant]# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
```
```shell
[root@lvm vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```

## Выделить том под /home

Выделяем том под /home по тому же принципу что делали для /var

```shell
[root@lvm vagrant]# lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
  Logical volume "LogVol_Home" created.
```
```shell
mkfs.xfs /dev/VolGroup00/LogVol_Home
```
```shell
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol_Home /mnt/
[root@lvm vagrant]# cp -aR /home/* /mnt/
[root@lvm vagrant]# rm -rf /home/*
[root@lvm vagrant]# umount /mnt
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol_Home /home/
```

Правим fstab для автоматического монтирования /home
```shell
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

**Сгенеровать файлы в /home/**
```shell
touch /home/file{1..20}
```

**Снять снапшот**
```shell
[root@lvm vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
```

**Удалить часть файлов**
```shell
[root@lvm vagrant]# ls /home/
file1  file10  file11  file12  file2  file3  file4  file5  file6  file7  file8  file9  vagrant
```

**Восстановить из снапшота**
```shell
[root@lvm vagrant]# umount /home
[root@lvm vagrant]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
[root@lvm vagrant]# mount /home
[root@lvm vagrant]# ls /home/
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9  vagrant
```
```shell
[root@lvm vagrant]# lsblk
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk 
├─sda1                       8:1    0    1M  0 part 
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:2    0    2G  0 lvm  /home
sdb                          8:16   0   10G  0 disk 
sdc                          8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0    253:3    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:4    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1    253:5    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:6    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk 
```

























