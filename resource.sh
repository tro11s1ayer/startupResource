#!/usr/bin/sh

apt update
apt install tor ssh openssh-server net-tools software-properties-common build-essential suckless-tools -y
apt install apparmor rkhunter auditd strace 

#Enable APT over HTTPS
sed -e 's/http:/https:/g' /etc/apt/sources.list
sed -e 's/http:/https:/g' /etc/apt/sources.list.d/*

#Remove PolKit setuid (pkexec workaround)
chmod 0755 /usr/bin/pkexec

#Set local IP address
export PRIVATE_IP=$(hostname -I | awk '{print $1}')

#Update/Install APT packages
apt update
for OUTPUT in $(dpkg --list | cut -d ' ' -f 3 | grep -v '+' | tail -n +5)
do
	apt install $OUTPUT -y
done
apt clean all
apt autoremove

#Configure OpenSSH-Server
ssh-keygen

SSH_STATUS="$(/etc/init.d/ssh status | grep 'Active' | cut -d ':' -f 2 | cut -d ' ' -f 2,3)"
if [$SSH_STATUS != "active (running)"]; then
	dpkg-reconfigure openssh-server
	/etc/init.d/ssh reload
fi
if [$SSH_STATUS == "active (running)"]; then
	/etc/init.d/ssh stop
	dpkg-reconfigure openssh-server
	/etc/init.d/ssh start
fi


#Install/Update Python Packages/Libraries
pip install --upgrade pip
pip install theano pillow opencv-python qiskit tensorflow keras scipy sklearn scikit-learn jupyter numpy matplotlib paramiko

for OUTPUT in $(pip list | tail -n +3 | cut -f 1 -d ' ')
do
	pip install --upgrade on $OUTPUT
done

#Disable IPv6 networking
sed -e "s/#net.ipv6.conf.all.disable_ipv6=1/net.ipv6.conf.all.disable_ipv6=1/g" /etc/sysctl.conf
sed -e "s/#net.ipv6.conf.default.disable_ipv6=1/net.ipv6.conf.default.disable_ipv6=1" /etc/sysctl.conf
sed -e "s/#net.ipv6.conf.lo.disable_ipv6=1/net.ipv6.conf.lo.disable_ipv6=1/g" /etc/sysctl.conf
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
