# update-apt-system
An update script for apt respositories.

In order to use it place the update.sh to a directory.
The program requires root access or to be run with SUDO


```
ex. sudo ./update.sh
```

In order to make update.sh excecutable, please run the following command uder the directory of the script:

```
chmod +x update.sh
```

this is a programm to update your system.

This are the available options:

```
This is a programm to update your system.
It also checks if below packages and commands are available and issues an update to them as well
*Flatpak
*Snap
*Rust
*Composer
*ClamAV

The programm requires root permitions.

USAGE:

./update.sh -[v|h|y|n|u]

Plain parameters:
	 -v 		 outputs version.
	 -h 		 play this message
	 -y 		 do not ask for updates, this is the default usage action
	 -n 		 ask for updates

Argument parameters:
	 -u <user> 	 Specific user name to run some commands like rustup

Double quotes variables
	 --version 	 outputs version.
	 --help 	 play this message

```

The script does:
update, upgrade, dist-upgrade, autoclean, autoremove
Also this script update (if installed):
flatpak, rust, composer, clam av
