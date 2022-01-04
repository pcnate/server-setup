#! /bin/sh
#
# author: Nathan Baker (unr34l-dud3)
# date: June 15th, 2017
# desc: setup users, install packages and add some scripts

# grab scripts
wget https://raw.githubusercontent.com/pcnate/server-setup/master/bin/apt-update.sh -O /usr/local/bin/apt-update
wget https://raw.githubusercontent.com/pcnate/server-setup/master/bin/ratom.sh -O /usr/local/bin/ratom
wget https://raw.githubusercontent.com/pcnate/server-setup/master/bin/la.sh -O /usr/local/bin/la

# allow executing scripts
chmod +x /usr/local/bin/apt-update
chmod +x /usr/local/bin/ratom
chmod +x /usr/local/bin/la

# update and install some basic packages
apt-get update

USER=nbaker
echo "Creating user: $USER"
adduser --quiet --gecos "" $USER --disabled-password
echo "$USER:Hunterway*" | chpasswd
usermod -aG sudo $USER
usermod -aG www-data $USER
chage -d 0 $USER
