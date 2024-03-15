#! /bin/sh
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
if [ -f /etc/debian_version ]; then
  apt-get update
fi
if [ -f /etc/fedora-release ]; then
  dnf check-update
fi


# check to see if apt-show-versions is installed, if not, then install it
if [ -f /etc/debian_version ] && \
   [ ! -x /usr/bin/apt-show-versions ]; then
  echo
  echo "Installing apt-show-versions"
  echo
  apt-get install -y apt-show-versions
fi

# show upgradeable packages
echo
echo "Displaying upgradeable packages..."
echo
# if debian based and apt-show-versions is installed
if [ -f /etc/debian_version ] && \
   [ -x /usr/bin/apt-show-versions ]; then
  apt-show-versions | grep upgradeable
fi
if [ -f /etc/fedora-release ]; then
  dnf list updates
fi

echo "Done"
echo
