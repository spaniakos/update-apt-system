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
It also checks if below packages and commands are available and issues an update to them as well
*Flatpak
*Snap
*Rust
*Composer
*ClamAV

This are the available options:

```
This is a program to update your system.

It also checks if below packages and commands are available and issues an update to them as well
Flatpak - Snap - Rust - Composer - ClamAV

The program requires root permissions.

./update.sh -[v|h|y|n|u]

Plain parameters:
	 -v 		 outputs version.
	 -h 		 display this message
	 -y 		 do not ask for updates, this is the default usage action
	 -n 		 ask for updates

Argument parameters:
	 -u <user> 	 Specific user name to run some commands like rustup

Double quotes variables
	 --version 	 outputs version.
	 --help 	 display this message
```

The script does:
update, upgrade, dist-upgrade, autoclean, autoremove
Also this script update (if installed):
Flatpak - Snap - Rust - Composer - ClamAV

Future Work:

```
* Consider adding updater to apt as a package
* Consider writing a function to auto hook the updater to a crontab or create a deamon and set auto-update itervals ( Not recommended for bleeding edge systems )
* Make the package runnable without sudo by asking sudo on the first command rather than not allowing the user to run it
* Add More updatable packages ( Uppon request or uppon usage )
```

Known Bugs:

```
* Snap is not getting udpated, solution is know, will give some time for someone to pick up the issue and get it fixed.
```
