#!/usr/bin/sh

cat /etc/apt/sources.list | sed -e 's/http:/https:/g'
cat /etc/apt/sources.list.d/* | sed -e 's/http:/https:/g'

chmod 0755 /usr/bin/pkexec

export PRIVATE_IP=$(hostname -I | awk '{print $1}')

#Update Repositories
apt update

#Install packages
apt install -y wget curl net-tools chkrootkit rkhunter snapd mono-complete
apt install -y apt-listbugs apt-listchanges debsecan debsums libpam-tmpdir libpam-usb debian-goodies libpam-cracklib libpam-passwdqc
apt install -y arpwatch arpon
apt install -y postfix 
apt install -y apache2 apache2-utils nginx php php7.4 ufw fail2ban apparmor openssh-server openssl tor git
apt install -y libapache2-mod-php libapache2-mod-php7.4 libapache2-mod-evasive libapache2-mod-security2 libapache2-mod-proxy-msrpc
apt install -y samba smbclient winbind libpam-winbind libnss-winbind
apt install -y systemd binutils gcc g++ netcdf-bin libopenmpi-dev
apt install -y automake autoconf make libtool cmake python
apt install -y build-essential
apt install -y python2 python2.7
apt install -y rdesktop ftp telnet ruby-full vsftpd
apt install -y mingw-w64 mingw-w64-common mingw-w64-i686-dev mingw-w64-tools mingw-w64-x86-64-dev

#Configure Postfix
postconf -e disable_vrfy_command=yes

#Configure Apache Server
htpasswd -c /etc/apache2/.htpasswd $USER
APACHE_STATUS="$(/etc/init.d/apache2 status | grep 'Active' | cut -d ':' -f 2 | cut -d ' ' -f 2,3)"
if [$APACHE_STATUS != "active (running)"]; then

	a2enmod evasive
	a2enmod proxy
	a2enmod php7.4
	a2enmod security2
	a2enmod ssl
	a2enmod proxy_msrpc
	a2enmod rewrite
	mkdir /etc/apache2/certificates
	cat 000-default.conf > /etc/apache2/sites-enabled/000-default.conf
	/etc/init.d/apache2 start

else
	a2enmod evasive
	a2enmod proxy
	a2enmod php7.4
	a2enmod security2
	a2enmod proxy_msrpc
	a2enmod ssl
	a2enmod rewrite

	mkdir /etc/apache2/certificates
	cat 000-default.conf > /etc/apache2/sites-enabled/000-default.conf
	/etc/init.d/apache2 restart
fi

#Restart Apache Server
if [$APACHE_STATUS == "active (running)"]; then
	/etc/init.d/apache2 restart
else
	/etc/init.d/apache2 start
fi

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


#Configure SMB Server
echo "[HTTP-Server] \n
\tcomment = HTTP-Server \n
\tpath = /var/www/html/ \n
\tread only = no \n
\tbrowsable = yes" >> /etc/samba/smb.conf
ufw allow samba
smbpasswd -c /etc/samba/smb.conf -a $USER
SMB_STATUS="$(/etc/init.d/smbd status | grep 'Active' | cut -d ':' -f 2 | cut -d ' ' -f 2,3)"
if [$SMB_STATUS != "active (running)"]; then
	#Do something with SMB Server
	/etc/init.d/smbd start
fi
if [$SMB_STATUS == "active (running)"]; then
	/etc/init.d/smbd stop
	#Do something with SMB Server
	/etc/init.d/smbd start
fi

#Update System Packages
apt dist-upgrade -y

#Disable IPv6 networking
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

systemctl enable --now snapd apparmor
systemctl start snapd.socket
snap install dotnet-sdk --classic --channel=6.0
snap install dotnet-runtime-60 --classic
snap alias dotnet-runtime-60.dotnet dotnet60
snap alias dotnet-sdk.dotnet dotnet
export DOTNET_ROOT=/snap/dotnet-sdk/current' >> ~/.bashrc
echo 'export DOTNET_ROOT=/snap/dotnet-sdk/current' >> ~/.bashrc

curl -o /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
alias nuget="mono /usr/local/bin/nuget.exe"
echo 'alias nuget="mono /usr/local/bin/nuget.exe"' >> ~/.bashrc
nuget update -self

