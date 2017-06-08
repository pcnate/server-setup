
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
echo '#! /bin/sh
#
# author: Nathan Baker (unr34l-dud3)
# date: February 16th, 2012
# desc: quick and dirty script to update apt and show upgradeable packages in one command

# check if this is run by root, if not then restart with sudo
if [ "$(id -u)" != "0" ]; then
        sudo $0
        exit 1
fi

# update using apt-get update
clear
echo
echo "Updating apt..."
echo
apt-get update


# check to see if apt-show-versions is installed, if not, then install it
if [ ! -x /usr/bin/apt-show-versions ]; then
        echo
        echo "Installing apt-show-versions"
        echo
        apt-get install -y apt-show-versions
fi

# execute apt-show-versions then use grep to show only upgradeable packages
echo
echo "Displaying upgradeable packages..."
echo
apt-show-versions | grep upgradeable

echo "Done"
echo
' > /bin/apt-update

chmod +x /bin/apt-update

apt-update

apt-get dist-upgrade

apt-get install htop bwm-ng sudo wget apt-show-versions -y


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
