Настройка PXE сервера для автоматической установки
Цель: Отрабатываем навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки
1. Следуя шагам из документа https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install установить и настроить загрузку по сети для дистрибутива CentOS8
В качестве шаблона воспользуйтесь репозиторием https://github.com/nixuser/virtlab/tree/main/centos_pxe
2. Поменять установку из репозитория NFS на установку из репозитория HTTP
3. Настройить автоматическую установку для созданного kickstart файла (*) Файл загружается по HTTP
4. (*) Автоматизировать процесс установки Cobbler cледуя шагам из документа https://cobbler.github.io/quickstart/