# homework-linux
homework for linux admin cources

   * [Содержание](#table-of-contents)
      * [Home Work #1](#Home-Work-1)
      * [Home Work #2](#Home-Work-2)
      * [Home Work #3](#Home-Work-3)
      * [Home Work #4](#Home-Work-4)
      * [Home Work #5](#Home-Work-5)
      * [Home Work #6](#Home-Work-6)
      * [Home Work #7](#Home-Work-7)
      * [Home Work #8](#Home-Work-8)
      * [Home Work #9](#Home-Work-9)
      * [Home Work #10](#Home-Work-10)
      * [Home Work #11](#Home-Work-11)
      * [Home Work #12](#Home-Work-12)
      * [Home Work #13](#Home-Work-13)
      * [Home Work #14](#Home-Work-14)
      * [Home Work #15](#Home-Work-15)
      
## Home Work #1

### С чего начинается Linux
Обновить ядро в базовой системе
Цель: Студент получит навыки работы с Git, Vagrant, Packer и публикацией готовых образов в Vagrant Cloud.
В материалах к занятию есть методичка, в которой описана процедура обновления ядра из репозитория. По данной методичке требуется выполнить необходимые действия. Полученный в ходе выполнения ДЗ Vagrantfile должен быть залит в ваш репозиторий. Для проверки ДЗ необходимо прислать ссылку на него.
Для выполнения ДЗ со * и ** вам потребуется сборка ядра и модулей из исходников.
Критерии оценки: Основное ДЗ - в репозитории есть рабочий Vagrantfile с вашим образом.
ДЗ со звездочкой: Ядро собрано из исходников
ДЗ с **: В вашем образе нормально работают VirtualBox Shared Folders

## Home Work #2

### Дисковая подсистема
Работа с mdadm
добавить в Vagrantfile еще дисков
сломать/починить raid
собрать R0/R5/R10 на выбор
прописать собранный рейд в конф, чтобы рейд собирался при загрузке
создать GPT раздел и 5 партиций

в качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда, конф для автосборки рейда при загрузке
*- доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом
<p>
**- перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).
Критерии оценки: - 4 принято - сдан Vagrantfile и скрипт для сборки, который можно запустить на поднятом образе. 5 - сделано доп задание

## Home Work 3

### Файловые системы и LVM
Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты script

*- на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt
Критерии оценки: основная часть обязательна
задание со звездочкой +1 балл

## Home Work 4

### NFS, FUSE
Vagrant стенд для NFS или SAMBA
NFS или SAMBA на выбор:

vagrant up должен поднимать 2 виртуалки: сервер и клиент
на сервер должна быть расшарена директория
на клиента она должна автоматически монтироваться при старте (fstab или autofs)
в шаре должна быть папка upload с правами на запись
требования для NFS: NFSv3 по UDP, включенный firewall

*- Настроить аутентификацию через KERBEROS

## Home Work 5

### Управление пакетами. Дистрибьюция софта
Размещаем свой RPM в своем репозитории
1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
2) создать свой репо и разместить там свой RPM
реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо

*реализовать дополнительно пакет через docker
Критерии оценки: 5 - есть репо и рпм
+1 - сделан еще и докер образ

## Home Work 6

### Загрузка системы
Работа с загрузчиком
1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

4(*). Сконфигурировать систему без отдельного раздела с /boot, а только с LVM
Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/
PV необходимо инициализировать с параметром --bootloaderareasize 1m
Критерии оценки: Описать действия, описать разницу между методами получения шелла в процессе загрузки.
Где получится - используем script, где не получается - словами или копипастой описываем действия.

## Home Work 7

### Bash
Пишем скрипт
написать скрипт для крона
который раз в час присылает на заданную почту
- X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
- Y запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
- все ошибки c момента последнего запуска
- список всех кодов возврата с указанием их кол-ва с момента последнего запуска
в письме должно быть прописан обрабатываемый временной диапазон
должна быть реализована защита от мультизапуска
Критерии оценки:
трапы и функции, а также sed и find +1 балл

## Home Work 8

### ZFS
Практические навыки работы с ZFS
Цель: Отрабатываем навыки работы с созданием томов export/import и установкой параметров. Определить алгоритм с наилучшим сжатием. Определить настройки pool’a Найти сообщение от преподавателей Результат: список команд которыми получен результат с их выводами

**1. Определить алгоритм с наилучшим сжатием**

Зачем:
Отрабатываем навыки работы с созданием томов и установкой параметров. Находим наилучшее сжатие.


Шаги:
- определить какие алгоритмы сжатия поддерживает zfs (gzip gzip-N, zle lzjb, lz4)
- создать 4 файловых системы на каждой применить свой алгоритм сжатия
Для сжатия использовать либо текстовый файл либо группу файлов:
- скачать файл “Война и мир” и расположить на файловой системе
wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8
либо скачать файл ядра распаковать и расположить на файловой системе

Результат:
- список команд которыми получен результат с их выводами
- вывод команды из которой видно какой из алгоритмов лучше


**2. Определить настройки pool’a**

Зачем:
Для переноса дисков между системами используется функция export/import. Отрабатываем навыки работы с файловой системой ZFS

Шаги:
- Загрузить архив с файлами локально.
https://drive.google.com/open?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Распаковать.
- С помощью команды zfs import собрать pool ZFS.
- Командами zfs определить настройки
- размер хранилища
- тип pool
- значение recordsize
- какое сжатие используется
- какая контрольная сумма используется
Результат:
- список команд которыми восстановили pool . Желательно с Output команд.
- файл с описанием настроек settings

 **3. Найти сообщение от преподавателей**

Зачем:
для бэкапа используются технологии snapshot. Snapshot можно передавать между хостами и восстанавливать с помощью send/receive. Отрабатываем навыки восстановления snapshot и переноса файла.

Шаги:
- Скопировать файл из удаленной директории. https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing
Файл был получен командой
zfs send otus/storage@task2 > otus_task2.file
- Восстановить файл локально. zfs receive
- Найти зашифрованное сообщение в файле secret_message

Результат:
- список шагов которыми восстанавливали
- зашифрованное сообщение

## Home Work 9

### Proc
Задания на выбор
1) написать свою реализацию ps ax используя анализ /proc
- Результат ДЗ - рабочий скрипт который можно запустить
2) написать свою реализацию lsof
- Результат ДЗ - рабочий скрипт который можно запустить
3) дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию
- Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли
4) реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice
- Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли
5) реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice
- Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли
Критерии оценки: 5 баллов - принято - любой скрипт

+1 балл - больше одного скрипта
<p>
+2 балла все скрипты

## Home Work #10

Systemd
Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):
1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig);
2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi);
3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами;
4. *Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.

## Home Work #11

Первые шаги с Ansible
Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible

Домашнее задание считается принятым, если:
- предоставлен Vagrantfile и готовый playbook/роль ( инструкция по запуску стенда, если посчитаете необходимым )
- после запуска стенда nginx доступен на порту 8080
- при написании playbook/роли соблюдены перечисленные в задании условия
Критерии оценки: Ставим 5 если создан playbook
Ставим 6 если написана роль

## Home Work #12

1. Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников
2. *Дать конкретному пользователю права работать с докером
и возможность рестартить докер сервис

## Home Work #13

Практика с SELinux
Цель: Тренируем умение работать с SELinux: диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.
1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.
К сдаче:
- README с описанием каждого решения (скриншоты и демонстрация приветствуются).

2. Обеспечить работоспособность приложения при включенном selinux.
- Развернуть приложенный стенд
https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.
К сдаче:
- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.
Критерии оценки:
Обязательно для выполнения:
- 1 балл: для задания 1 описаны, реализованы и продемонстрированы все 3 способа решения;
- 1 балл: для задания 2 описана причина неработоспособности механизма обновления зоны;
- 1 балл: для задания 2 реализован и продемонстрирован один из способов решения;
Опционально для выполнения:
- 1 балл: для задания 2 предложено более одного способа решения;
- 1 балл: для задания 2 обоснованно(!) выбран один из способов решения.

## Home Work #14

Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен
отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)
Определите разницу между контейнером и образом
Вывод опишите в домашнем задании.
Ответьте на вопрос: Можно ли в контейнере собрать ядро?

Задание со * (звездочкой)
Создайте кастомные образы nginx и php, объедините их в docker-compose.
После запуска nginx должен показывать php info.
Все собранные образы должны быть в docker hub

## Home Work #15

Настройка мониторинга
Настроить дашборд с 4-мя графиками
1) память
2) процессор
3) диск
4) сеть

настроить на одной из систем
- zabbix (использовать screen (комплексный экран))
- prometheus - grafana

(*) использование систем примеры которых не рассматривались на занятии
(список возможных систем был приведен в презентации)

в качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего