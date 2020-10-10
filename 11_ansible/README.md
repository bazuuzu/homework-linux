Для проверки сделать Vagrant up
Перейти на http://192.168.11.150:8080/ или сделать curl http://192.168.11.150:8080

## Как выполнялось:

```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ vagrant ssh-config
Host nginx #Имя хоста
  HostName 127.0.0.1 #ip-адрес
  User vagrant #Имя пользователя, под которым подключаемся
  Port 2222 #Порт, который проброшен на 127.0.0.1
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/novoselov/homework-linux/11_ansible/.vagrant/machines/nginx/virtualbox/private_key #Путь до приватного ключаansible
  IdentitiesOnly yes
  LogLevel FATAL
```

Сделал папку inventory и в ней nginx.yml
```
nginx:
  hosts:
    host1:
      ansible_host: 127.0.0.1
      ansible_port: 2222
      ansible_ssh_private_key_file: /home/novoselov/homework-linux/11_ansible/.vagrant/machines/nginx/virtualbox/private_key
```

Затем сделал файл ansible.cfg
```
[defaults]
inventory = inventory/nginx.yml
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False                             
```

Проверяем доступность
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible web -m ping
host1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```

Теперь, когда мы убедились, что у нас все подготовлено - установлен
Ansible, поднят хост для теста и Ansible имеет к нему доступ, мы можем
конфигурировать наш хост.

Для начала воспользуемся Ad-Hoc командами и выполним некоторые
удаленные команды на нашем хосте.

Посмотрим какое ядро установлено на хосте:
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible nginx -m command -a "uname -r"
host1 | CHANGED | rc=0 >>
3.10.0-1127.el7.x86_64
```
Проверим статус сервиса firewalld
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible nginx -m systemd -a name=firewalld
host1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
```
Установим пакет epel-release на наш хост
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible nginx -m yum -a "name=epel-release state=present" -b
```

Напишем простой Playbook который будет делать одно из действий,
которое мы делали на прошлом слайде - а именно: установку пакета
epel-release. Создайте файл epel.yml со следующим содержимым:
```
---
- name: Install EPEL Repo
  hosts: nginx
  become: true
  tasks:
    - name: Install EPEL Repo package from standard repo
      yum:
        name: epel-release
        state: present
```

```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible-playbook epel.yml 

PLAY [Install EPEL Repo] *******************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************************
ok: [host1]

TASK [Install EPEL Repo package from standard repo] ****************************************************************************************************************************************
ok: [host1]

PLAY RECAP *********************************************************************************************************************************************************************************
host1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Допустим создам плейбук с установкой nano:
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible-playbook nano.yml 

PLAY [Install nano] ************************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************************
ok: [host1]

TASK [Install nano package from standard repo] *********************************************************************************************************************************************
changed: [host1]

PLAY RECAP *********************************************************************************************************************************************************************************
host1                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

За основу возьмем уже созданный нами файл epel.yml (я его переименуя в
nginx.yml). И первым делом добавим в него установку пакета NGINX.
Секция будет выглядеть так:
```
    - name: NGINX | Install NGINX package from EPEL Repo
      yum:
        name: nginx
        state: latest
      tags:
        - nginx-package
        - packages
      
```

```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible-playbook nginx.yml

PLAY [NGINX | Install and configure NGINX] **********************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************
ok: [host1]

TASK [NGINX | Install EPEL Repo package from standart repo] *****************************************************************************************************************************************
changed: [host1]

TASK [NGINX | Install NGINX package from EPEL Repo] *************************************************************************************************************************************************
changed: [host1]

PLAY RECAP ******************************************************************************************************************************************************************************************
host1                      : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Или так как мы добавили теги, то можно запустить только нужный тег:
Выведем все теги:
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible-playbook nginx.yml --list-tags

playbook: nginx.yml

  play #1 (nginx): NGINX | Install and configure NGINX  TAGS: []
      TASK TAGS: [epel-package, nginx-package, packages]
```
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible-playbook nginx.yml -t nginx-package

PLAY [NGINX | Install and configure NGINX] **********************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************
ok: [host1]

TASK [NGINX | Install NGINX package from EPEL Repo] *************************************************************************************************************************************************
ok: [host1]

PLAY RECAP ******************************************************************************************************************************************************************************************
host1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Далее добавим шаблон для конфига NGINX и модуль, который будет
копировать этот шаблон на хост
```
    - name: NGINX | Create NGINX config file from template
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags:
        - nginx-configuration
```
Добавим переменную с портом 8080
```
---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  vars:
    nginx_listen_port: 8080
```

Сделал директорию templates с файлом nginx.conf.j2. Сожержимое шаблона:
```
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
```

Теперь создадим handler и добавим notify к копирования шаблона. Теперь
каждый раз когда конфиг будет изменяться - сервис перезагрузиться.
Секция с handlers будет выглядеть следуящим образом:
```
  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
        enabled: yes
    
    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded
```
Добавим Notify
```
    - name: NGINX | Install NGINX package from EPEL Repo
      yum:
        name: nginx
        state: latest
      notify:
        - restart nginx
      tags:
        - nginx-package
        - packages
    - name: NGINX | Create NGINX config file from template
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify:
        - reload nginx
      tags:
        - nginx-configuration
```
Запустим плейбук
```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ ansible-playbook nginx.yml

PLAY [NGINX | Install and configure NGINX] **********************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************
ok: [host1]

TASK [NGINX | Install EPEL Repo package from standart repo] *****************************************************************************************************************************************
ok: [host1]

TASK [NGINX | Install NGINX package from EPEL Repo] *************************************************************************************************************************************************
ok: [host1]

TASK [NGINX | Create NGINX config file from template] ***********************************************************************************************************************************************
changed: [host1]

RUNNING HANDLER [reload nginx] **********************************************************************************************************************************************************************
changed: [host1]

PLAY RECAP ******************************************************************************************************************************************************************************************
host1                      : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

Переходим на http://192.168.11.150:8080/ или делаем curl

```
novoselov@ubunzuzu:~/homework-linux/11_ansible$ curl http://192.168.11.150:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css"> 
  ...
```

Добавляем в Vagrantfile:
```
          box.vm.provision :ansible do |ansible|
            ansible.inventory_path = "inventory/nginx.yml"	
            ansible.limit = $name
                  ansible.playbook = "nginx.yml"
          end
```