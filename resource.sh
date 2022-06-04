#!/usr/bin/sh

sudo apt update
sudo apt install tor ssh openssh-server net-tools software-properties-common build-essential suckless-tools -y
sudo apt install apparmor rkhunter auditd strace 

#Enable APT over HTTPS
sudo sed -e 's/http:/https:/g' /etc/apt/sources.list
sudo sed -e 's/http:/https:/g' /etc/apt/sources.list.d/*

#Remove PolKit setuid (pkexec workaround)
sudo chmod 0755 /usr/bin/pkexec

#Set local IP address
export PRIVATE_IP=$(hostname -I | awk '{print $1}')

#Update/Install APT packages
sudo apt update
sudo apt upgrade
sudo apt autoremove
sudo apt autoclean

#Configure OpenSSH-Server
ssh-keygen

SSH_STATUS="$(/etc/init.d/ssh status | grep 'Active' | cut -d ':' -f 2 | cut -d ' ' -f 2,3)"
if [$SSH_STATUS != "active (running)"]; then
	sudo dpkg-reconfigure openssh-server
	/etc/init.d/ssh reload
fi
if [$SSH_STATUS == "active (running)"]; then
	sudo /etc/init.d/ssh stop
	sudo dpkg-reconfigure openssh-server
	sudo /etc/init.d/ssh start
fi

#Update Ruby packages
sudo apt update
sudo apt install ruby ruby2.7 ruby2.7-dev
sudo gem update

#Install/Update Python Packages/Libraries
pip install --upgrade pip
pip install theano pillow opencv-python qiskit tensorflow keras scipy sklearn scikit-learn jupyter numpy matplotlib paramiko

for OUTPUT in $(pip list | tail -n +3 | cut -f 1 -d ' ')
do
	pip install --upgrade on $OUTPUT
done

#Disable IPv6 networking
sudo echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf
sudo echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf
sudo echo 'net.ipv6.conf.lo.disable_ipv6=1' >. /etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
