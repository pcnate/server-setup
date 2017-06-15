
# add la alias
LA_COMMAND="alias la='clear;echo -n \"Directory of: \";pwd;echo;ls --color=always -lah'"

if grep -Fxq "$LA_COMMAND" /root/.bashrc
then :
else
	echo "$LA_COMMAND" >> /root/.bashrc
fi

if grep -Fxq "$LA_COMMAND" /etc/skel/.bashrc
then :
else
	echo "$LA_COMMAND" >> /etc/skel/.bashrc
fi

# create the apt-update script
wget https://raw.githubusercontent.com/dpndbl/server-setup/master/bin/apt-update.sh -O /bin/apt-update
wget https://raw.githubusercontent.com/dpndbl/server-setup/master/bin/ratom.sh -O /usr/local/bin/ratom

chmod +x /bin/apt-update
chmod +x /usr/local/bin/ratom

apt-get update

apt-get dist-upgrade -y

apt-get install htop bwm-ng sudo wget apt-show-versions fail2ban libpam-systemd dbus screen -y


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
