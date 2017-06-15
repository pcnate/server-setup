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
