Сделал 3 пользователей:
```
useradd day && useradd night && useradd friday
```

Задал им пароли Qwerty12
```
echo "Qwerty12" | passwd --stdin day
echo "Qwerty12" | passwd --stdin night
echo "Qwerty12" | passwd --stdin friday
```

В nano /etc/security/time.conf добавил:
```
*;*;day;Al0800-2000
*;*;night;!Al0800-2000
*;*;friday;Fr
```

В nano /etc/pam.d/sshd добавил:
```
account    required     pam_time.so
```

Получилось в этом блоке
```
...
account    required     pam_nologin.so
account    required     pam_time.so
account    include      password-auth
...
```

```
[root@pam vagrant]# cat /etc/pam.d/login
#%PAM-1.0
auth [user_unknown=ignore success=ok ignore=ignore default=bad] pam_securetty.so
auth       substack     system-auth
auth       include      postlogin
account    required     pam_time.so
account    required     pam_nologin.so
account    include      system-auth
password   include      system-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_console.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
session    include      postlogin
-session   optional     pam_ck_connector.so
```

В итоге пользователей не пускало когда не нужно было

```
[root@pam vagrant]# ssh night@localhost
night@localhost's password: 
Authentication failed.
```

## Приступим к заданию

Модуль не входит по умолчанию, установим его из epel
```
yum install -y epel-release
yum install -y pam_script
```

Добавим пользователей и пароль
```
useradd test_user
echo "Qwerty12" | passwd --stdin test_user
useradd test_admin
echo "Qwerty12" | passwd --stdin test_admin
```

Создадим группу и добавим в неё пользователя test_admin
```
groupadd admin
usermod -a -G admin test_admin
```

Заменяем строку, если устновлен параметр no. s - поиск и замена, g - во всех строках
```
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
```

Вставляем строку по номеру
```
sed -i "2i auth  required  pam_script.so"  /etc/pam.d/sshd
```

Вставляем скрипт
```
cat <<'EOT' > /etc/pam_script
#!/bin/bash
if [[ `grep $PAM_USER /etc/group | grep 'admin'` ]]
then
exit 0
fi
if [[ `date +%u` > 1 ]]
then
exit 1
fi
EOT
```

Даём ему права на выполнение
```
chmod +x /etc/pam_script
```

Рестарт ssh
```
systemctl restart sshd
```

### Для проверки можно подправить в скрипте строку

```
if [[ `date +%u` > 5 ]]
```

На нужный день и попробовать залогиниться по ssh под пользователями test_user и test_admin и посмотреть что получится