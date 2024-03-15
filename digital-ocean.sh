#! /bin/sh
#
# author: Nathan Baker <pcnate@gmail.com>
# date: January 3rd, 2022
# desc: setup users, install packages and add some scripts on a Digital Ocean VM. Use ssh keys

# check if wget is installed, if not then install it
if [ ! -x /usr/bin/wget ]; then
  if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install wget -y
  fi
  if [ -f /etc/fedora-release ]; then
    dnf check-update
    dnf install wget -y
  fi
  if [ -f /etc/centos-release ] || \
     [ -f /etc/almalinux-release ]; then
    yum check-update
    yum install wget nano -y
  fi
fi

# grab scripts
cp ./bin/apt-update.sh /usr/local/bin/apt-update
cp ./bin/la.sh         /usr/local/bin/la
wget https://raw.githubusercontent.com/aurora/rmate/master/rmate -O /usr/local/bin/rmate

# allow executing scripts
chmod +x /usr/local/bin/apt-update
chmod +x /usr/local/bin/la
chmod +x /usr/local/bin/rmate

# update and install some basic packages on debian based systems
if [ -f /etc/debian_version ]; then
  apt-get update
  apt-get dist-upgrade -y
  apt-get install sudo git htop bwm-ng sudo apt-show-versions fail2ban screen autossh open-vm-tools unzip -y
fi

# update and install some basic packages on fedora based systems
if [ -f /etc/fedora-release ]; then
  dnf check-update
  dnf update -y
  dnf install sudo git htop bwm-ng sudo fail2ban screen autossh open-vm-tools unzip -y
fi

# update and install some basic packages on centos based systems
if [ -f /etc/centos-release ] \
   [ -f /etc/almalinux-release ]; then
  yum check-update
  yum update -y
  yum install sudo git sudo open-vm-tools unzip -y
fi

# install oh-my-posh
wget https://ohmyposh.dev/install.sh -O - | bash
cp ./oh-my-posh/quick-term.omp.json /usr/local/bin/quick-term.omp.json

# set a variable to be evaled and appended to the .bashrc file
OH_MY_POSH_INIT='oh-my-posh --init --shell bash --config /usr/local/bin/quick-term.omp.json'

# remove existing oh-my-posh init from the .bashrc file
sed -i '/oh-my-posh/d' /etc/skel/.bashrc
sed -i '/oh-my-posh/d' /root/.bashrc

# enable oh-my-posh for root and new users
echo "eval \"\$( $OH_MY_POSH_INIT )\"" >> /etc/skel/.bashrc
echo "eval \"\$( $OH_MY_POSH_INIT )\"" >> /root/.bashrc

# accept the first argument as the user to create
if [ -z "$1" ]; then
  USER=pcnate
else
  USER=$1
fi

# accept the second argument as the password for the user
if [ -z "$2" ]; then
  PASSWORD=Hunterway*
else
  PASSWORD=$2
fi

# create my user
echo "Creating user: $USER"
if [ -f /etc/debian_version ]; then
  adduser --quiet --gecos "" $USER --disabled-password
  echo "$USER:$PASSWORD" | chpasswd
fi
if [ -f /etc/fedora-release ] || \
   [ -f /etc/centos-release ] || \
   [ -f /etc/almalinux-release ]; then
  useradd $USER
  echo "$PASSWORD" | passwd $USER --stdin
fi

# if groups exist, add my user to them
if getent group wheel; then
  usermod -aG wheel $USER
fi
if getent group sudo; then
  usermod -aG sudo $USER
fi
if getent group docker; then
  usermod -aG docker $USER
fi
if getent group www-data; then
  usermod -aG www-data $USER
fi

# remove existing oh-my-posh init from the .bashrc file just in case
sed -i '/oh-my-posh/d' /home/$USER/.bashrc
echo "eval \"\$( $OH_MY_POSH_INIT )\"" >> /home/$USER/.bashrc

# generate ssh keys and move the authorized keys to my user
su -c "ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -b 8192 -N ''" $USER
mv /root/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys
chown $USER:$USER /home/$USER/.ssh/authorized_keys

# force a password change if the user password is the default
if [ "$PASSWORD" = "Hunterway*" ]; then
  chage -d 0 $USER
fi
