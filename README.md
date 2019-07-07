About
-----
nextcloud installer is made for people who have difficulty installing programs and configuring them.

Or for people that are to lazy to copy paste from a tutorial. I made this script because I want to learn programming in Bash.

Feel free to contribute to this script. Give your idea a shot and post it with a Pull Request.


Prerequisites
-------------

To follow this guide and use the script to setup Nextcloud, you will need to have
a Raspberry Pi Model 3B(+) or later with an ethernet port, an SD or microSD card
(depending on the model) with Raspbian installed, a power adapter appropriate to
 the power needs of your model, and an ethernet cable or wifi adapter to connect your Pi to your
router or gateway. It is recommended that you use a fresh image of Raspbian
Buster Lite from https://raspberrypi.org/downloads, but if you don't,
be sure to make a backup image of your existing installation before proceeding.
You should also setup your Pi with a static IP address (see either source
  1 or 2 at the bottom of this Readme) but it is not required as the script can do this for you.
  You will need to have your router forward TCP port 80 and TCP/UDP port 443.
  Enabling SSH on your Pi is also highly recommended, so that
  you can run a very compact headless server without a monitor or keyboard and
  be able to access it even more conveniently. This can be done by entering ```sudo raspi-config```
  and go to interfacing options and go to P2 SSH and enable this service.

Installation
-----------------


```shell
wget https://raw.githubusercontent.com/squadramunter/nextcloud_installer/master/setup
sudo chmod +x setup
sudo ./setup
```
You see a menu where you can choose from 2 options.

![alt text](https://raw.githubusercontent.com/squadramunter/nextcloud_installer/master/nextcloud_installer.png)

First option is to start the Auto Installer.

Second option is to request a Let's Encrypt certificate for your Nextcloud installation if you did not setup SSL for your FQDN.

Please notice that the second option does not work if you have setup Nextcloud for local use.

For Ubuntu users please remove the # sign for PHP and Certbot

## Optional if you don't have the latest PHP
## sudo add-apt-repository -y ppa:ondrej/php
sudo add-apt-repository -y ppa:ondrej/php

## Optional if you don't have the latest certbot
## sudo add-apt-repository -y ppa:certbot/certbot
sudo add-apt-repository -y ppa:certbot/certbot

Removing Nextcloud
----------------
At this point there is no auto remove option in the list. But this is planned as a feature project. Don't ask about this as a issue.

Contribute
----------------
I like to share my project and all improvement to this script are welcome. Share your idea and I take a look if your idea is suitable for this script.

