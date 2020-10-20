#Модуль не входит по умолчанию, установим его из epel
yum install -y epel-release
yum install -y pam_script
#Добавим пользователей и пароль
useradd test_user
echo "Qwerty12" | passwd --stdin test_user
useradd test_admin
echo "Qwerty12" | passwd --stdin test_admin
#Создадим группу и добавим в неё пользователя test_admin
groupadd admin
usermod -a -G admin test_admin
#Заменяем строку, если устновлен параметр no. s - поиск и замена, g - во всех строках
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
#Вставляем строку по номеру
sed -i "2i auth  required  pam_script.so"  /etc/pam.d/sshd
#Вставляем скрипт
cat <<'EOT' > /etc/pam_script
#!/bin/bash
if [[ `grep $PAM_USER /etc/group | grep 'admin'` ]]
then
exit 0
fi
if [[ `date +%u` > 5 ]]
then
exit 1
fi
EOT
#Даём ему права на выполнение
chmod +x /etc/pam_script
#Рестарт ssh
systemctl restart sshd