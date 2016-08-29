#!/bin/sh
#MIT Licence 
#Copyright (c) Ethan Perry, Andy Lyu
echo "Welcome to CyberPatriot. I'll be your guide."

unalias -a #Get rid of aliases

#--------- Change Root Password ----------------
passwd
echo "Please change other user's passwords too"

#--------- Check and Change UID's of 0 not Owned by Root ----------------
cut -d: -f1,3 /etc/passwd | egrep ':0$' | cut -d: -f1 | grep -v root >> zerouidusers

#--------- Allow Only Root Cron ----------------
cd /etc/
cd /etc/
/bin/rm -f cron.deny at.deny
echo root >cron.allow
echo root >at.allow
/bin/chown root:root cron.allow at.allow
/bin/chmod 400 cron.allow at.allow

#--------- Securing Apache ----------------
chown -R root:root /etc/apache2
chown -R root:root /etc/apache

if [ -e /etc/apache2/apache2.conf ]; then
echo \<Directory \> >> /etc/apache2/apache2.conf
echo -e ' \t AllowOverride None' >> /etc/apache2/apache2.conf
echo -e ' \t Order Deny,Allow' >> /etc/apache2/apache2.conf
echo -e ' \t Deny from all' >> /etc/apache2/apache2.conf
echo \<Directory \/\> >> /etc/apache2/apache2.conf
echo UserDir disabled root >> /etc/apache2/apache2.conf
fi

#--------- Manual File Inspection ----------------
crontab -e #make sure crontab is empty
cut -d: -f1,3 /etc/passwd | egrep ':[0-9]{4}$' | cut -d: -f1 > listofusers
echo root >> listofusers
nano /etc/apt/sources.list #check for malicious sources
nano /etc/resolv.conf #make sure if safe, use 8.8.8.8 for name server
nano /etc/hosts #make sure is not redirecting
nano /etc/rc.local #should be empty except for 'exit 0'
nano /etc/lightdm/lightdm.conf #allow_guest=false, remove autologin
nano /etc/ssh/sshd_config #PermitRootLogin no, Protocol 2, X11Forwarding no, PermitEmptyPasswards no
nano /etc/sudoers #make sure sudoers file is clean. There should be no NOPASSWD
nano listofusers #No unauthorized users
nano zerouidusers #There should be no one in this. If there is, change the uid of the user

#--------- Manual Network Inspection ----------------
lsof-i -n -P
netstat -tulpn

#--------- Update Using Apt-Get ----------------
apt-get update --no-allow-insecure-repositories
apt-get dist-upgrade -y
apt-get install -f -y
apt-get autoremove -y
apt-get autoclean -y
apt-get check

#--------- Download programs ----------------
apt-get install-y chkrootkit portsentry lynis ufw sysv-rc-conf nessus clamav rkhunter apparmor apparmor-profiles
apt-get install-y --reinstall coreutils

#--------- Configure Automatic Updates ----------------
cat /etc/apt/apt.conf.d/10periodic | grep APT::Periodic::Update-Package-Lists | grep 0 >> /dev/null
if [ $?==0 ]; then
sed -i 's/APT::Periodic::Update-Package-Lists "0"/APT::Periodic::Update-Package-Lists "1"/g' /etc/apt/apt.conf.d/10periodic

#--------- Delete em' pirates, eh? (Delete Dangerous Files) ----------------
find / -name '*.mp3' -type f -delete
find / -name '*.torrent' -type f -delete
find / -name '*.mov' -type f -delete
find / -name '*.mp4' -type f -delete
find / -name '*.avi' -type f -delete
find / -name '*.mpg' -type f -delete
find / -name '*.mpeg' -type f -delete
find / -name '*.flac' -type f -delete
find / -name '*.m4a' -type f -delete
find / -name '*.flv' -type f -delete
find / -name '*.ogg' -type f -delete
find /home -name '*.gif' -type f -delete
find /home -name '*.png' -type f -delete
find /home -name '*.jpg' -type f -delete
find /home -name '*.jpeg' -type f -delete
cd / && ls -laR | grep rwxrwxrwx | grep -v "lrwx" &> /tmp/777s
echo "777 Files: "
cat /tmp/777s

#--------- Setup Firewall ----------------
#Please verify that the firewall wont block any services, such as an Email server, when defaulted.
#I will back up iptables for you in and put it in /iptables/rules.v4.bak and /iptables/rules.v6.bak

#Backup
mkdir /iptables/
iptables-save > /iptables/rules.v4.bak
ip6tables-save > /iptables/rules.v6.bak

#Uninstall UFW and install iptables
apt-get purge ufw
apt-get install iptables
apt-get install ip6tables

#Clear out and default iptables
iptables -t nat -F
iptables -t mangle -F
iptables -t nat -X
iptables -t mangle -X
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -t nat -X
ip6tables -t mangle -X
ip6tables -F
ip6tables -X
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

#--------- Secure /etc/sysctl.conf ----------------
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
sysctl -w net.ipv4.conf.all.secure_redirects=0
sysctl -w net.ipv4.conf.default.secure_redirects=0
sysctl -p

#--------- Scan For Vulnerabilities and viruses ----------------
chkrootkit -q
rkhunter --update
rkhunter --propupd
rkhunter -c
lynis -c
freshclam
clamscan -r -i --exclude-dir="^/sys" /