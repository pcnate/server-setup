
#! /bin/sh
#
# author: Nathan Baker (unr34l-dud3)
# date: June 15th, 2017
# desc: setup users, install packages and add some scripts

# grab scripts
wget https://raw.githubusercontent.com/pcnate/server-setup/master/bin/apt-update.sh -O /usr/local/bin/apt-update
wget https://raw.githubusercontent.com/pcnate/server-setup/master/bin/la.sh -O /usr/local/bin/la
wget https://raw.githubusercontent.com/aurora/rmate/master/rmate -O /usr/local/bin/rmate

# allow executing scripts
chmod +x /usr/local/bin/apt-update
chmod +x /usr/local/bin/ratom
chmod +x /usr/local/bin/la

# update and install some basic packages
apt-get update
apt-get dist-upgrade -y
apt-get install sudo git htop bwm-ng sudo wget apt-show-versions fail2ban libpam-systemd dbus screen autossh open-vm-tools -y

# add auto reboot
crontab -l 2>/dev/null | { cat; echo "0 1 * * 0 /sbin/reboot >/dev/null 2>&1"; } | crontab -


# set user permissions
echo 'umask 002' >> /etc/skel/.bashrc

# create users
while read p; do
        USER=$( echo "${p}" | egrep -o '[a-z]+@' | sed -n 's/@//p' )

        if id "$USER" >/dev/null 2>&1; then :
        else
                echo "Creating user: $USER"
                adduser --quiet --gecos "" $USER --disabled-password
                #useradd -p $( perl -e 'print( $ARGV[0], "password")' "Hunterway*") -m $USER
                echo "$USER:Hunterway*" | chpasswd
                usermod -aG sudo $USER
                usermod -aG www-data $USER
                
                # generate passwordless keys for easier use
                su -c "ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -b 8192 -N ''" $USER

                # deploy ssh keys
                mkdir /home/$USER/.ssh
                cat /root/.ssh/authorized_keys | grep $USER > /home/$USER/.ssh/authorized_keys
                chown $USER:$USER /home/$USER/.ssh -R
                chmod 0700 /home/$USER/.ssh -R
                
                #force password change
                chage -d 0 $USER
        fi

done < /root/.ssh/authorized_keys

rm /root/.ssh/authorized_keys
