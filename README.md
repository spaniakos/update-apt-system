# update-apt
An update script for apt respositories.

In order to use it place the update.sh to a directory.
The program requires root access or to be run with SUDO

ex. sudo ./update.sh

In order to make update.sh excecutable, please run the following command uder the directory of the script:
chmod +x update.sh

this is a programm to update your system.

This are the available options:

./update.sh -[v|h|y|n]
-v 	outputs version.
-h 	play this message
--help 	play this message
-y 	do not ask for updates, this is the default usage action
-n 	ask for updates

The script does:
update, upgrade, dist-upgrade, autoclean, autoremove.
