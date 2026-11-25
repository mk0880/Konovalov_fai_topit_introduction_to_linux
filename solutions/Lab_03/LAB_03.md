<center>

# **Министерство науки и высшего образования Российской Федерации**

# ФЕДЕРАЛЬНОЕ ГОСУДАРСТВЕННОЕ АВТОНОМНОЕ ОБРАЗОВАТЕЛЬНОЕ УЧРЕЖДЕНИЕ ВЫСШЕГО ОБРАЗОВАНИЯ

# **НАЦИОНАЛЬНЫЙ ИССЛЕДОВАТЕЛЬСКИЙ УНИВЕРСИТЕТ ИТМО**

# ITMO University


## ФАКУЛЬТЕТ ПРИКЛАДНОЙ ИНФОРМАТИКИ

&nbsp;

&nbsp;

### Отчет по лабораторной работе №3
### по дисциплине "Основы ОС Linux"
### Тема: Подсистема безопасности Linux: пользователи, права, SSH, процессы
### Вариант 1

&nbsp;

&nbsp;

</center>

<div style="text-align: right;">

**Выполнил:**<br>
Коновалов Матвей Александрович<br>
Top IT PRO 1.2

&nbsp;

**Проверил:**

</div>

&nbsp;

&nbsp;

<center>

Санкт-Петербург<br>
2026 г.

</center>


## Артефакты
### Part 1
#### *sshd -T*
* logingracetime 30
* maxauthtries 2
* permitrootlogin yes
#### who
* kma-1    sshd pts/3   2026-11-24 22:39 (10.0.2.2)
* root     sshd pts/2   2026-11-24 22:38 (10.0.2.2)
* root     pts/0       2026-11-24 22:29
* vboxuser seat0       2026-11-24 22:20
* vboxuser tty3        2026-11-24 22:20
* kma-1    seat0       2026-11-24 22:20
* kma-1    tty2        2026-11-24 22:20
#### ss -tnp | grep ':22'
* ESTAB 0      0          10.0.2.15:22       10.0.2.2:52815 users:(("sshd-session",pid=4475,fd=7),("sshd-session",pid=4435,fd=7))
* ESTAB 0      0          10.0.2.15:22       10.0.2.2:59067 users:(("sshd-session",pid=4286,fd=7),("sshd-session",pid=4276,fd=7))
#### SCP
* scp -r -P 2221 "C:\Users\matve\Desktop\infinity-blade-3-pc" kma-1@127.0.0.1:~/
* scp -r -P 2221 kma-1@127.0.0.1:~/infinity-blade-3-pc "C:\Users\matve\Desktop\infinity-blade-3-pc(copy)"

### Part 2
#### *script31*
```
#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <count> <start_number>"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Error: run this script as root."
    exit 1
fi

if ! [[ "$1" =~ ^[1-9][0-9]*$ && "$2" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: arguments must be positive integers."
    exit 1
fi

count=$1
start=$2

for ((i=start; i<start+count; i++)); do
    username="u$i"
    password="DerParol$i"

    if id "$username" &>/dev/null; then
        echo "$username already exists, skipping."
    else
        useradd -m -s /bin/bash "$username" &&
        echo "$username:$password" | chpasswd &&
        echo "Created $username."
    fi
done
```

#### *id*
* uid=1002(u1) gid=1002(u1) groups=1002(u1),1007(project)
* uid=1003(u2) gid=1003(u2) groups=1003(u2),1007(project)
* uid=1004(u3) gid=1004(u3) groups=1004(u3)
* uid=1005(u4) gid=1005(u4) groups=1005(u4)
* uid=1006(u5) gid=1006(u5) groups=1006(u5)

#### *getent passwd*
* u1:x:1002:1002::/home/u1:/bin/bash
* u2:x:1003:1003::/home/u2:/bin/bash
* u3:x:1004:1004::/home/u3:/bin/bash
* u4:x:1005:1005::/home/u4:/bin/bash
* u5:x:1006:1006::/home/u5:/bin/bash

#### *getent group*
* project:x:1007:u1,u2,u3
* u1:x:1002:
* u2:x:1003:

### Part 3
#### ls -l /DATA
* drwxrwsrwt 2 root project  4096 Nov 25 00:25 sec1
* drwxr-s--- 2 u1   dataread 4096 Nov 25 00:31 sec2
* drwxr-sr-x 2 root project  4096 Nov 25 00:33 sec3
* -rw-rw-r-- 1 u1   project    14 Nov 25 00:21 test-u1.txt

### Part 4

#### *sshd -T*
* permitrootlogin no
* pubkeyauthentication yes
* passwordauthentication no
* authorizedkeysfile .ssh/authorized_keys

#### *SSH authentication tests*
* `ssh -p 2221 kma-1@127.0.0.1` 
* `ssh -p 2221 root@127.0.0.1`
* `ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password -p 2221 kma-1@127.0.0.1`

#### *SCP*
* `scp -P 2221 kma-1@127.0.0.1:/home/kma-1/script31 "$env:USERPROFILE\Desktop\script31"`


### Part 5

#### `/etc/sudoers.d/u1`

```
u1 ALL=(root) /usr/bin/passwd, !/usr/bin/passwd root
```

#### Restriction checks

| Command | Result |
|---|---|
| `sudo passwd u2` | Allowed |
| `sudo passwd root` | Denied |
| `sudo ls /root` | Denied |

#### PID–PPID chain

```
systemd(1)
└── sshd(5987)
    └── sshd-session(6398)
        └── sshd-session(6407)
            └── bash(6408)
                └── sudo(6561)
                    └── sudo(6563)
                        └── bash
```

#### `script32`

File: `/home/kma-1/script32`

```
#!/bin/bash

while true; do
    echo "$(date '+%F %T') PID=$$ PPID=$PPID" >> /home/kma-1/script32.log
    sleep 2
done
```
### Part 5

* см. прикреплённые файлы

#### SIGHUP

* Terms on exit without nohup
* PPID on exit with `nohup`: changed to `1`.

```
PID    PPID USER   STAT CMD
7903   1    kma-1  S    /bin/bash /home/kma-1/script32
```

## Ответы на вопросы
1. Парольная фраза защищает закрытый SSH-ключ: даже если файл ключа украдут, без фразы им нельзя будет воспользоваться.

2. Отпечаток помогает проверить подлинность SSH-сервера и защититься от подмены. Если он изменился, возможно, сервер переустановили или происходит атака — нужно проверить причину.

3. Нет. В `/etc/shadow` хранятся хеши паролей с разными случайными солями, поэтому одинаковые пароли могут иметь разные хеши.

4. 

| Атрибут | Сокращение | Для файла | Для каталога |
|---|---|---|---|
| Чтение | r | Чтение содержимого | Просмотр списка файлов |
| Запись | w | Изменение содержимого | Создание, удаление и переименование файлов |
| Выполнение | x | Запуск программы | Доступ к каталогу и его содержимому |
| SUID | s | Запуск с правами владельца файла | Не имеет обычного значения |
| SGID | s | Запуск с правами группы файла | Новые файлы наследуют группу каталога |
| Sticky bit | t | Практически не используется | Удалять файлы могут только их владельцы, владелец каталога и root |

5. Удаление файла изменяет содержимое каталога, поэтому нужны права `w` и `x` на каталог. Sticky bit ограничивает удаление файлов их владельцами, владельцем каталога и root.

6. `setfacl -m u:user:rwx file` — выдаёт пользователю все права на файл. Для задания 3 можно использовать `setfacl -m u:u4:r-x /DATA/sec2`, чтобы дать u4 чтение и доступ к каталогу без изменения владельца и групп.

7. `su` переключает пользователя, `su -` дополнительно загружает его окружение, а `sudo` запускает отдельную команду с повышенными правами. `sudo` безопаснее, потому что не требует постоянно использовать пароль root и позволяет ограничивать команды.

8. Подстановочные знаки могут разрешить выполнение большего количества команд или аргументов, чем планировалось. Это может позволить обойти ограничения и получить лишние привилегии.

9. `SIGTERM` просит процесс завершиться и может быть перехвачен. `SIGKILL` принудительно завершает процесс и не может быть перехвачен.

10. При закрытии SSH-сессии оболочка может отправить фоновому процессу `SIGHUP`, из-за чего он завершится. `nohup` игнорирует этот сигнал. После закрытия сессии процесс становится сиротой, и его PPID меняется на `1` (systemd).

11. Зомби — это завершившийся процесс, запись о котором ещё хранится в таблице процессов, пока родитель не заберёт его статус. Убить его через `kill -9` нельзя, потому что он уже завершён.

12. `grep` показывает строки, записанные в конфигурационных файлах, а `sshd -T` — реальные эффективные настройки SSH-сервера. Например, `grep` может показать `PermitRootLogin yes`, а `sshd -T` — `permitrootlogin no`, если значение переопределено в другом конфигурационном файле.

13. Если программа с SUID принадлежит root, она запускается с правами root. Уязвимость в такой программе может позволить обычному пользователю получить полный доступ к системе.