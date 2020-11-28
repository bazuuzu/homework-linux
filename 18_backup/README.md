В Vagrantfile сделал 2 машины и подключил дополнительный диск на 2Гб. На обе машины установлен BORG из репозитория


```
[root@borg vagrant]# mkfs.ext4 /dev/sdb
[root@borg vagrant]# mkdir /var/backup/
[root@borg vagrant]# mount /dev/sdb /var/backup/
[root@borg vagrant]# df -Th             
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  841M   37G   3% /
devtmpfs                        devtmpfs  487M     0  487M   0% /dev
tmpfs                           tmpfs     496M     0  496M   0% /dev/shm
tmpfs                           tmpfs     496M  6.7M  490M   2% /run
tmpfs                           tmpfs     496M     0  496M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs     100M     0  100M   0% /run/user/1000
/dev/sdb                        ext4      2.0G  6.0M  1.8G   1% /var/backup
```

Создадим пользователя borg на хосте client
```
[root@client vagrant]# useradd -m borg
```

Затем нам нужно сгенерировать ssh-ключ на сервере и на client пользователя borg

```
[root@borg vagrant]# ssh-keygen
[root@borg vagrant]# cat ~/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDR0E485c7XsdOSrYriJRkgTg/1L7HxEJw6x5Nq1fTdu5jbcQ6KmjkqUiUdHVPwQpKRfRCfEJM8wYGrqZ5/nsEL6te8G476Ma2FpG6D2ezFqZy2Bou6B21Tw1OM/NOXBYiyWbC5tIbVvk6ogYmhd+p76OWxdqL5PIiV9lLmHXj7pbIy9/rfSTD/9sJ3CYT4tnIHk35O5HcMAsW/q5Cd3IlsXzz97iEbeEXbF6StlIJiNKkB85kffkvPC4LpAtqrt4YQ+BX2FpF/mMikff9TestfuhdkZl6jz95SxmRbM+zNAoNR5Md1suPsI39OIsUT9bQolfzKyXs1RuFkV1LxhvdP root@borg

```

На клиенте делаем
```
[root@client vagrant]# mkdir ~borg/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDR0E485c7XsdOSrYriJRkgTg/1L7HxEJw6x5Nq1fTdu5jbcQ6KmjkqUiUdHVPwQpKRfRCfEJM8wYGrqZ5/nsEL6te8G476Ma2FpG6D2ezFqZy2Bou6B21Tw1OM/NOXBYiyWbC5tIbVvk6ogYmhd+p76OWxdqL5PIiV9lLmHXj7pbIy9/rfSTD/9sJ3CYT4tnIHk35O5HcMAsW/q5Cd3IlsXzz97iEbeEXbF6StlIJiNKkB85kffkvPC4LpAtqrt4YQ+BX2FpF/mMikff9TestfuhdkZl6jz95SxmRbM+zNAoNR5Md1suPsI39OIsUT9bQolfzKyXs1RuFkV1LxhvdP root@borg" > ~borg/.ssh/authorized_keys
[root@client vagrant]# chown -R borg:borg ~borg/.ssh
```

Будем шифровать с помощью blake2. Пароль: 1234
На клиенте делаем

```
[root@client vagrant]# chmod -R 777 /var/backup/
```

На сервере

```
[root@borg vagrant]# borg init --encryption=repokey-blake2 borg@192.168.11.151:/var/backup/EtcRepo
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: y
Your passphrase (between double-quotes): "1234"
```

Проверяем на клиенте

```
[root@client vagrant]# cat /var/backup/EtcRepo/config[repository]version = 1segments_per_dir = 1000max_segment_size = 524288000
append_only = 0
storage_quota = 0
additional_free_space = 0
id = 268aa7845a60c7eb5ce0c7ce0fae47de3143272edd1ec52273deefd068d481ed
key = hqlhbGdvcml0aG2mc2hhMjU2pGRhdGHaAZ4A1pB+Lj+3giUzCC5V+3P5boKowlqu9NV0cL
        3oUgg5ObMOUEEHWpqD2EGanoW5zr2a4+gTzgh5l+i6RmMC2e52elJ2AmxunCmCTRgAUtgm
        5Jh+i1FoK6M5ejK5ZbrD10U2z1RumQC4XTVgR+9UVLhB5TPtliJt5/LX4gt6dw1IYf2gne
        aY379NJSX0NHMZOXDFvV0WyKErXO8+2sF9/1w18lU+MV/U76Ir9JYgmVUumLWTVF599R/M
        AOH8OY7HD3Ty2/BpPjIqLyQn/odVecQVCHMfjS+/p5VqlcTzRvdJCuAnwplRVefrWHOL3j
        FVyDGObUrsvEtRmT7vz1Z8FChMXnMUhiNUBEXp11q0DJ3+G3HcXNLTUpohOBBOyvyr1NhX
        FGS1eFlgVtjeAW7Mu4yIB1/5hbYtyXeUZZyqI+zrwLKqZsRF7B2GDTwX7dk2EaZNXPEYJ8
        xNhwFhqHBz7rX6QkYOfk9IyIiLPyyXfZDKgx+59PBCI6VqKuoAxdY/2kiMiIO0EJLJus8p
        DoHjR12+3YAx5fuKHASEefv1+zOkaGFzaNoAIGhZbJa018CzZGch/46V3Xcl9rit7xA7xr
        tHOczsyUGGqml0ZXJhdGlvbnPOAAGGoKRzYWx02gAgvCeBWbkJnO1PngkDdzXnRXYmRC5h
        +DrJV90DrT6LBg2ndmVyc2lvbgE=
```

Как программно указать кодовую фразу для шифрования? (https://borgbackup.readthedocs.io/en/stable/faq.html?highlight=BORG_PASSPHRASE#how-can-i-specify-the-encryption-passphrase-programmatically)
Есть несколько способов указать кодовую фразу без вмешательства человека. Я выбрал BORG_PASSPHRASE. Парольную фразу можно указать с помощью переменной enviroment. Часто это самый простой вариант, но он может быть небезопасным, если сценарий, который его устанавливает, доступен для чтения всем.BORG_PASSPHRASE
```
export BORG_PASSPHRASE='1234'.
```

### Скрипт

- Для логгирования:
```
LOG=/var/log/borg_backup.log

borg create \
  --stats --list --debug --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-server-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc 2>> ${LOG}
```

- Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов

```
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-daily=93 \
  --keep-monthly=12 2>> ${LOG}
```

- Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.

Для этого настроим таймер и сервис systemd

```
[root@borg ~]# cat /etc/systemd/system/borg-backup.service
[Unit]
Description=Borg /etc backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/root/borg-backup.sh
```

```
[root@borg ~]# cat /etc/systemd/system/borg-backup.timer
[Unit]
Description=Borg backup timer

[Timer]
#run hourly
OnBootSec=3min
OnUnitActiveSec=5min
Unit=borg-backup.service

[Install]
WantedBy=multi-user.target
```
```
[root@borg ~]# systemctl daemon-reload
[root@borg ~]# systemctl enable --now borg-backup.timer
Created symlink from /etc/systemd/system/multi-user.target.wants/borg-backup.timer to /etc/systemd/system/borg-backup.timer.
```

- Написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение.

### Протестируем

Создадим папку с файлами внутри /etc

```
[root@borg ~]# mkdir /etc/TESTDIR
[root@borg ~]# touch /etc/TESTDIR/file{1..8}
[root@borg ~]# ll /etc/TESTDIR
total 0
-rw-r--r--. 1 root root 0 Nov 28 15:54 file1
-rw-r--r--. 1 root root 0 Nov 28 15:54 file2
-rw-r--r--. 1 root root 0 Nov 28 15:54 file3
-rw-r--r--. 1 root root 0 Nov 28 15:54 file4
-rw-r--r--. 1 root root 0 Nov 28 15:54 file5
-rw-r--r--. 1 root root 0 Nov 28 15:54 file6
-rw-r--r--. 1 root root 0 Nov 28 15:54 file7
-rw-r--r--. 1 root root 0 Nov 28 15:54 file8
```

Запустим скрипт вручную
```
[root@borg ~]# ./borg-backup.sh 
```

Проверим, что вышло
```
[root@borg ~]# borg list borg@192.168.11.151:/var/backup/EtcRepo
etc-server-2020-11-28_15:58:50       Sat, 2020-11-28 15:58:51 [481c2c0ea580d354e2a749da8d1ebb1035068ab7793c4d44456cd17641f47d5a]
etc-server-2020-11-28_16:01:31       Sat, 2020-11-28 16:01:32 [5c0dcabfd6ad51d4226556af4fc37da2c566e80f87ba58fac6b5df9b406664ae]
[root@borg ~]# borg list borg@192.168.11.151:/var/backup/EtcRepo::etc-server-2020-11-28_15:58:50
...
drwxr-x--- root   root          0 Sat, 2020-11-28 14:52:27 etc/audit
drwxr-x--- root   root          0 Sat, 2018-05-12 18:52:18 etc/audit/rules.d
-rw------- root   root          0 Sat, 2018-05-12 18:52:18 etc/audit/rules.d/audit.rules
-rw-r----- root   root        127 Wed, 2018-04-11 04:50:24 etc/audit/audit-stop.rules
-rw-r----- root   root        805 Wed, 2018-04-11 04:50:24 etc/audit/auditd.conf
```

Удалим папку
```
[root@borg ~]# rm -rf /etc/TESTDIR/
[root@borg ~]# ll /etc/TESTDIR/
ls: cannot access /etc/TESTDIR/: No such file or directory
```

Достанем её из бэкапа. Нужно создать директорию и примонтировать в неё деректорий с бэкапом
```
[root@borg ~]# mkdir /mnt/borg
[root@borg ~]# ll /mnt     
total 0
drwxr-xr-x. 2 root root 6 Nov 28 16:07 borg
[root@borg ~]# borg mount borg@192.168.11.151:/var/backup/EtcRepo::etc-server-2020-11-28_15:58:50 /mnt/borg/
[root@borg ~]# ll /mnt/borg/etc/TESTDIR/
total 0
-rw-r--r--. 1 root root 0 Nov 28 15:54 file1
-rw-r--r--. 1 root root 0 Nov 28 15:54 file2
-rw-r--r--. 1 root root 0 Nov 28 15:54 file3
-rw-r--r--. 1 root root 0 Nov 28 15:54 file4
-rw-r--r--. 1 root root 0 Nov 28 15:54 file5
-rw-r--r--. 1 root root 0 Nov 28 15:54 file6
-rw-r--r--. 1 root root 0 Nov 28 15:54 file7
-rw-r--r--. 1 root root 0 Nov 28 15:54 file8
```

Вернём назад и отмонтируем
```
[root@borg ~]# cp -Rp /mnt/borg/etc/TESTDIR/ /etc/TESTDIR
[root@borg ~]# ll /etc/TESTDIR/total 0
-rw-r--r--. 1 root root 0 Nov 28 15:54 file1
-rw-r--r--. 1 root root 0 Nov 28 15:54 file2
-rw-r--r--. 1 root root 0 Nov 28 15:54 file3
-rw-r--r--. 1 root root 0 Nov 28 15:54 file4
-rw-r--r--. 1 root root 0 Nov 28 15:54 file5
-rw-r--r--. 1 root root 0 Nov 28 15:54 file6
-rw-r--r--. 1 root root 0 Nov 28 15:54 file7
-rw-r--r--. 1 root root 0 Nov 28 15:54 file8
[root@borg ~]# borg umount /mnt/borg/
```