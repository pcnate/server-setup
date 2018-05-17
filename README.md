# server-setup
Setup Linux servers with users, ssh keys and basic packages etc

Build the server using the latest version of Debian Linux
https://www.debian.org/distrib/netinst

Add primary developer ssh public keys to the authorized_keys file
```bash
sudo su -
ssh-keygen -f ~/.ssh/id_rsa -t rsa -b 8192 -N ''
nano /root/.ssh/authorized_keys
```
copy text from https://dpndbl.itglue.com/569683/docs/1888733#version=published&documentMode=view

Setup the basic server with the following script
curl https://github.com/dpndbl/server-setup/blob/master/server-setup.sh | sudo -E bash -
