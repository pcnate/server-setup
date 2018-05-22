# server-setup
Setup Linux servers with users, ssh keys and basic packages etc

For a physical machine, ensure BIOS is setup to power on the machine after a power outage and not require a keyboard

Build the server using the latest version of Debian Linux
https://www.debian.org/distrib/netinst

Set root password and save it in ITGLUE
create user account `setupuser` and use whatever password you want for setting it up

Add primary developer ssh public keys to the authorized_keys file
```bash
su -
apt-get install -y sudo curl
ssh-keygen -f ~/.ssh/id_rsa -t rsa -b 8192 -N ''
nano /root/.ssh/authorized_keys
```
copy text from https://dpndbl.itglue.com/569683/docs/1888733#version=published&documentMode=view

Set a static ip if it is not already. you can do this later too if you are not onsite, you need internet access to continue
https://linuxconfig.org/how-to-setup-a-static-ip-address-on-debian-linux

Be sure to whitelist the server

Setup the basic server with the following script
```bash
curl https://raw.githubusercontent.com/dpndbl/server-setup/master/server-setup.sh | sudo -E bash -
```
Change the passwords for your account and the dpndbl account. Default password is `Hunterway*`
```bash
#switch to that user
su - username

# change the password
passwd

# then exit
exit
```

Lock the accounts that you did not change the password to with
```bash
# lock a user out
sudo chage -E0 username
```

use `exit` to logout and the log back in as yourself

delete the setup user
```bash
sudo deluser setupuser --remove-home --quiet
```

You should now be able to ssh into the machine
