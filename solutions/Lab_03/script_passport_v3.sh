#!/bin/bash

SUDO=""

usage() {
    echo "Usage: $0 [-h] [report_file]"
    echo "  report_file  output file (default: PASSPORT/inventory.txt)"
    echo "  -h           show this help"
}

die() {
    echo "Error: $1" >&2
    exit "${2:-1}"
}

check_privileges() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi
    if id -nG | grep -qw sudo && sudo -v; then
        SUDO="sudo"
        return 0
    fi
    die "no sufficient privileges: run as root or as a user from the sudo group."
}

check_tool() {
    if ! PATH="$PATH:/usr/sbin:/sbin" command -v "$1" >/dev/null 2>&1; then
        echo "Tool '$1' not found. Install package: $2" >&2
        return 1
    fi
}

write_section() {
    { echo "$1"; cat "$2"; echo; } >> "$REPORT"
}

log_run() {
    echo "date: $(date)  user: $(whoami)  format: v3" >> PASSPORT/log/report.log
}

cleanup() {
    find PASSPORT -type f -name '*.tmp' -delete
}

if [ "$1" = "-h" ]; then
    usage
    exit 0
fi
REPORT=${1:-PASSPORT/inventory.txt}

check_privileges
check_tool lscpu util-linux || exit 1
check_tool dmidecode dmidecode || exit 1
check_tool lspci pciutils || exit 1

mkdir -p PASSPORT/log PASSPORT/tmp
T=PASSPORT/tmp
trap cleanup EXIT
trap 'exit 1' INT TERM

{ date; hostname; } > $T/host.tmp
{ whoami; who; } > $T/user.tmp
{ pwd; ls; } > $T/dir.tmp
uname -a > $T/kernel.tmp
grep -E '^(NAME|VERSION)=' /etc/os-release > $T/os.tmp

lscpu | grep -E 'Model name|MHz|^CPU\(s\)|L1d|L1i|L2|L3' > $T/cpu.tmp
grep -E 'MemTotal|MemFree' /proc/meminfo > $T/mem.tmp
$SUDO dmidecode -t baseboard | grep -E 'Manufacturer|Product Name' > $T/board.tmp
$SUDO dmidecode -t bios      | grep -E 'Vendor|Version|Release Date' > $T/bios.tmp

lspci > $T/pci.tmp

check_tool lastlog2 lastlog2 && lastlog2 > $T/lastlog2.tmp 2>/dev/null
getent passwd | awk -F: '$1 == "root" || $3 >= 1000 {print $1, $3}' > $T/userlist.tmp
while read -r name uid; do
    user_groups=$(id -nG "$name")
    last_login=$(awk -v u="$name" '$1 == u {print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' $T/lastlog2.tmp 2>/dev/null)
    pw_change=$(LC_ALL=C $SUDO chage -l "$name" 2>/dev/null | sed -n 's/^Last password change[[:space:]]*:[[:space:]]*//p')
    echo "$name | UID: $uid | groups: $user_groups | last login: ${last_login:-no data} | password changed: ${pw_change:-no data}"
done < $T/userlist.tmp > $T/users.tmp

: > $T/sshd_T.tmp
check_tool sshd openssh-server && $SUDO sshd -T 2>/dev/null | grep -E '^(permitrootlogin|port|logingracetime|maxauthtries|passwordauthentication|pubkeyauthentication) ' > $T/sshd_T.tmp
while read -r param value; do
    if grep -Eiq "^[[:space:]]*$param[[:space:]]" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
        source="set in config"
    else
        source="default"
    fi
    echo "$param $value ($source)"
done < $T/sshd_T.tmp > $T/sshd.tmp

: > $T/top5.tmp
check_tool ps procps && ps -eo pid,ppid,user,%mem,comm --sort=-%mem | head -6 > $T/top5.tmp

empty_pw=$($SUDO awk -F: '$2 == "" {print $1}' /etc/shadow 2>/dev/null | tr '\n' ' ')
uid0=$(getent passwd | awk -F: '$3 == 0 && $1 != "root" {print $1}' | tr '\n' ' ')
{ echo "empty password: ${empty_pw:-none}"; echo "UID 0 (not root): ${uid0:-none}"; } > $T/suspicious.tmp

find /usr/bin /usr/sbin -type f -perm -4000 2>/dev/null > $T/suid.tmp

{ echo 'SYSTEM INFO'; echo; } > $REPORT
for f in host user dir kernel os cpu mem board bios pci users sshd top5 suspicious suid; do write_section "${f} info:" $T/$f.tmp; done

log_run

echo "Done. File in: $REPORT"
echo 'Log in: PASSPORT/log/report.log'