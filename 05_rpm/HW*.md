Установим Docker
```
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
```
Создаём публичный репозиторий на hub.docker.com
Создаём контейнер с приложением c cowsay, которое выводит нарисованную корову, повторяющую написанный текст. Будем использовать образ ubuntu с тегом latest
```
docker run -it --name cowsay --hostname cowsay ubuntu bash
```
Повап в наш созданный контейнер устанавливаем прилозжение cowsay
```
apt update
apt -y upgrade
apt -y install cowsay
```
Создаём символьную ссылку, чтобы не писать полный путь к приложению
```
ln -s /usr/games/cowsay /usr/bin/cowsay
```
Проверяем работоспособность
```
root@cowsay:/# cowsay "Hello OTUS"
 ____________
< Hello OTUS >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

**Превращаем контейнер в образ**

Выходим из контейнера и собираем образ
```
docker login
docker commit cowsay sna1030/cowsay
```
```
[root@docker vagrant]# docker run sna1030/cowsay cowsay "Test"
 ______
< Test >
 ------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
Пушим
```
docker push sna1030/cowsay
```

Удаляем контейнеры и образы
```
[root@docker vagrant]# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                          PORTS               NAMES
0b7405410c97        sna1030/cowsay      "cowsay Test"       48 seconds ago       Exited (0) 45 seconds ago                           loving_edison
9bb61f87d1ef        ubuntu              "bash"              About a minute ago   Exited (0) About a minute ago                       cowsay
[root@docker vagrant]# docker rm 0b7405410c97 9bb61f87d1ef
0b7405410c97
9bb61f87d1ef
root@docker vagrant]# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
```
[root@docker vagrant]# docker images -a
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sna1030/cowsay      latest              dddb1e103f38        2 minutes ago       143MB
ubuntu              latest              4e2eef94cd6b        46 hours ago        73.9MB
[root@docker vagrant]# docker rmi dddb1e103f38 4e2eef94cd6b
```
Проверяем:
```
docker run sna1030/cowsay cowsay "Test for OTUS" 
```
Образ скачался и запустился
```
[root@docker vagrant]# docker run sna1030/cowsay cowsay "Test for OTUS"
Unable to find image 'sna1030/cowsay:latest' locally
latest: Pulling from sna1030/cowsay
54ee1f796a1e: Pull complete 
f7bfea53ad12: Pull complete 
46d371e02073: Pull complete 
b66c17bbf772: Pull complete 
78e9eb34e02c: Pull complete 
Digest: sha256:49c4a7cab85830fcec7196ece4541385c501dac5a723ae58a5a511114d158e72
Status: Downloaded newer image for sna1030/cowsay:latest
 _______________
< Test for OTUS >
 ---------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
```
[root@docker vagrant]# docker images -a
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sna1030/cowsay      latest              dddb1e103f38        3 minutes ago       143MB
[root@docker vagrant]# docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      PORTS               NAMES
3b6c38f9a873        sna1030/cowsay      "cowsay 'Test for OT…"   36 seconds ago      Exited (0) 30 seconds ago                       cranky_leakey
```