# server-setup
Setup Linux servers with users, ssh keys and basic packages etc

For a physical machine, ensure BIOS is setup to power on the machine after a power outage and not require a keyboard

Build the server using the latest version of Debian Linux
https://www.debian.org/distrib/netinst

Set root password and save it in ITGLUE
create user account `setupuser` and use whatever password you want for setting it up

Add primary developer ssh public keys to the authorized_keys file
```bash
sudo su -
ssh-keygen -f ~/.ssh/id_rsa -t rsa -b 8192 -N ''
nano /root/.ssh/authorized_keys
```
copy text from https://dpndbl.itglue.com/569683/docs/1888733#version=published&documentMode=view

Setup the basic server with the following script
```bash
curl https://github.com/dpndbl/server-setup/blob/master/server-setup.sh | sudo -E bash -
```
Change the passwords for your account and the dpndbl account. Default password is `Hunterway*`
```bash
su - username
```

Lock the accounts that you did not change the password to with
```bash
chage -E0 username
```

delete the setup user
```bash
sudo deluser setupuser --remove-home --quiet
```

You should now be able to ssh into the machine
