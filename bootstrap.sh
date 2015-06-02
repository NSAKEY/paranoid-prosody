#!/bin/bash

# This should be considered a fork of Micah Lee's tor-relay-bootstrap.
# You can find that project here: https://github.com/micahflee/tor-relay-bootstrap
# His bash script had exactly the structure I needed so it got repurposed.

# check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# update software
echo "== Updating software"
apt-get update
apt-get dist-upgrade -y

apt-get install -y lsb-release


# add official Tor repository
if ! grep -q "http://deb.torproject.org/torproject.org" /etc/apt/sources.list; then
    echo "== Adding the official Tor repository"
    echo "deb http://deb.torproject.org/torproject.org `lsb_release -cs` main" >> /etc/apt/sources.list
    gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -
    apt-get update
fi

# Add the official Prosody repository
if ! grep -q "deb http://packages.prosody.im/debian" /etc/apt/sources.list; then
    echo "== Adding the official Prosody repository"
    echo "deb http://packages.prosody.im/debian `lsb_release -cs` main" >> /etc/apt/sources.list
    wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
    apt-get update
fi

# install prosody and tor, plus related packages
echo "== Installing Prosody and Tor"
apt-get install -y deb.torproject.org-keyring tor tor-arm tor-geoipdb prosody lua-event
service tor stop
service prosody stop

# SSL/TLS prep for prosody
openssl genrsa -out /etc/prosody/certs/xmpp.key 4096
openssl req -new -key /etc/prosody/certs/xmpp.key -out /etc/prosody/certs/xmpp.crt
openssl dhparam -out /etc/prosody/certs/dhparam.pem 4096
chown prosody:prosody /etc/prosody/certs/*
chmod 600 /etc/prosody/certs/*

# configure tor
cp $PWD/etc/tor/torrc /etc/tor/torrc

# configure prosody
cp $PWD/etc/prosody/prosody.cfg.lua /etc/prosody/prosody.cfg.lua

# configure firewall rules
echo "== Configuring firewall rules"
apt-get install -y debconf-utils
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
apt-get install -y iptables iptables-persistent
cp $PWD/etc/iptables/rules.v4 /etc/iptables/rules.v4
cp $PWD/etc/iptables/rules.v6 /etc/iptables/rules.v6
chmod 600 /etc/iptables/rules.v4
chmod 600 /etc/iptables/rules.v6
iptables-restore < /etc/iptables/rules.v4
ip6tables-restore < /etc/iptables/rules.v6

# configure automatic updates
echo "== Configuring unattended upgrades"
apt-get install -y unattended-upgrades apt-listchanges
cp $PWD/etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
service unattended-upgrades restart

# install and configure apparmor
apt-get install -y apparmor apparmor-profiles apparmor-utils
sed -i.bak 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 apparmor=1 security=apparmor"/' /etc/default/grub
update-grub
cp $PWD/etc/apparmor.d/usr.bin.prosody /etc/apparmor.d/usr.bin.prosody

# install tlsdate
if [ "$(lsb_release -cs)" == "wheezy" ]; then
	# tlsdate isn't in wheezy
	if [ "$((echo 3.5; uname -r) | sort -cV 2>&1)" == "" ]; then
		# if we have seccomp (>= linux 3.5) we can backport it
		if ! grep -q "wheezy-backports" /etc/apt/sources.list; then
			echo "deb http://ftp.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
			apt-get update
		fi
		apt-get install -y tlsdate
	fi
else
	# later than wheezy
	apt-get install -y tlsdate
fi

# final instructions
echo ""
echo "== Try SSHing into this server again in a new window as well as connecting to XMPP, to confirm the firewall isn't broken"
echo ""
echo "== TO DO LIST:"
echo ""
echo "1. Run 'cat /etc/prosody/certs/xmpp.crt' and submit its contents to your friendly neighborhood Certificate Authority."
echo ""
echo "2. Configure DNS."
echo ""
echo "3. Edit /etc/prosody/prosody.cfg.lua so that both cases of 'example.org' are replaced with your domain."
echo ""
echo "4. After you reboot, you can run 'aa-enforce /etc/apparmor.d/usr.bin.prosody' if you want."
echo ""
echo "5. After the reboot, be sure to run 'cat /var/lib/tor/xmpp/hostname' to get your hidden service address."
echo ""
echo "6. The option to allow SSH as an authenticated hidden service has been supplied. Just read the comments in /etc/tor/torrc."
echo ""
echo "== REBOOT THIS SERVER"
