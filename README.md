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


# External Hard Drives
# NTFS ( harder )
you can access it from Windows 
```bash
sudo apt-get install ntfs-3g exfat-fuse -y

# show your disks
sudo fdisk -l

# get the UUID 
sudo blkid /dev/sdb1

#backup fstab file, just in case
sudo cp /etc/fstab /root/fstab

# add the disk to /etc/fstab using the partitions UUID
sudo sh - c 'echo UUID=\"4860F68460F677D0\" /media/fogbackup/ ntfs auto,hotplug,nofail,nls-utf8,umask-0222,uid-1000,gid-1000,rw 0 0 >> /etc/fstab'

# verify contents and changed UUID if you haven't already
sudo nano /etc/fstab

# check disks, then test mount then check again
df -h
sudo mount -a
df -h

# if it shows up, powering it off, then wait a few secs, then back on to see if it disappears and shows up again
# try rebooting with the drive turned off
```

# ext4 ( easy )
requires Mac or Linux to read the disk
```bash
# show your disks
sudo fdisk -l

#backup fstab file, just in case
sudo cp /etc/fstab /root/fstab

# make sure the disk is labeled
sudo e2label /dev/sdb fogbackup

# add the following line to /etc/fstab
sudo sh - c 'echo LABEL=fogbackup         /media/fogbackup/   ext4    auto,nofail,defaults     0        2' >> /etc/fstab'

# verify contents and changed UUID if you haven't already
sudo nano /etc/fstab

# check disks, then test mount then check again
df -h
sudo mount -a
df -h

# if it shows up, powering it off, then wait a few secs, then back on to see if it disappears and shows up again
# try rebooting with the drive turned off
```
