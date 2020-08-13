## Делаем RAID 10

Подключили в Vagrantfile 6 дисков

<details>
<summary>Прописываем в Vagrantfile</summary>
	:disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 250, # Megabytes
			:port => 1
		},
		:sata2 => {
                       :dfile => './sata2.vdi',
                       :size => 250, # Megabytes
			:port => 2
		},
                :sata3 => {
                       :dfile => './sata3.vdi',
                       :size => 250, # Megabytes
                       :port => 3
                },
                :sata4 => {
                       :dfile => './sata4.vdi',
                       :size => 250, # Megabytes
                       :port => 4
                },
                :sata5 => {
                       :dfile => './sata5.vdi',
                       :size => 250, # Megabytes
                       :port => 5
                },
                :sata6 => {
                       :dfile => './sata6.vdi',
                       :size => 250, # Megabytes
                       :port => 6
                }

	}
</details>

Устанавливаем необходимие утилиты
```
yum install -y mdadm smartmontools hdparm gdisk
```
Создаём RAID командой
```
mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg
```
Создаём конфигурационный файл для массива
```
mkdir /etc/mdadm
touch /etc/mdadm/mdadm.conf
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

## Ломаем и чиним RAID

Искусственно ломаем одно из блочных устройств командой (делаем под рутом)
```
mdadm /dev/md0 --fail /dev/sde
```
На выходе получили
```
mdadm: set /dev/sde faulty in /dev/md0
```
Проверяем
```
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdg[5] sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [UUU_UU]
      
unused devices: <none>
```
Видим диск, который зафейлился

Командой
```
mdadm -D /dev/md0
```
Видим
```
    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

       3       8       64        -      faulty   /dev/sde
```
Удаляем диск из массива
```
[root@otuslinux vagrant]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
```
"Вставляем" новый диск
```
[root@otuslinux vagrant]# mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```
Проверяем
```
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sde[6] sdg[5] sdf[4] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
      
unused devices: <none>
```

## Создаём партиции

Изначально имеем:

```
[root@otuslinux vagrant]# df -hT
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  489M     0  489M   0% /dev
tmpfs          tmpfs     496M     0  496M   0% /dev/shm
tmpfs          tmpfs     496M  6.7M  489M   2% /run
tmpfs          tmpfs     496M     0  496M   0% /sys/fs/cgroup
/dev/sda1      xfs        40G  4.6G   36G  12% /
tmpfs          tmpfs     100M     0  100M   0% /run/user/1000
```

Создаём раздел GPT на RAID

```
parted -s /dev/md0 mklabel gpt
```

Создаём разделы

```
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
```

Создаём на них файловую систему ext4
```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```
И монитруем их по каталогам

```
mkdir -p /raid/part{1,2,3,4,5}
```
```
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```

Получаем

```
[root@otuslinux vagrant]# df -hT
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  489M     0  489M   0% /dev
tmpfs          tmpfs     496M     0  496M   0% /dev/shm
tmpfs          tmpfs     496M  6.7M  489M   2% /run
tmpfs          tmpfs     496M     0  496M   0% /sys/fs/cgroup
/dev/sda1      xfs        40G  4.6G   36G  12% /
tmpfs          tmpfs     100M     0  100M   0% /run/user/1000
/dev/md0p1     ext4      139M  1.6M  127M   2% /raid/part1
/dev/md0p2     ext4      140M  1.6M  128M   2% /raid/part2
/dev/md0p3     ext4      142M  1.6M  130M   2% /raid/part3
/dev/md0p4     ext4      140M  1.6M  128M   2% /raid/part4
/dev/md0p5     ext4      139M  1.6M  127M   2% /raid/part5
```
