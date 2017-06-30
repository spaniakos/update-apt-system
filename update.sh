#!/bin/bash
# ------------------------------------------------------------------
# [Spaniakos] Update script
#          The script updates the system.
# ------------------------------------------------------------------
SCRIPT_NAME="$0"
VERSION="1.0"
AUTHOR="G.Spanos - gspanos@makeasite.gr"
CREATE_DATE="2/9/2016"
LAST_UPDATE="2/9/2016"

ROOT_UID=0	# Only users with $UID 0 have root privileges.
E_NOTROOT=87	# Non-root exit error.
E_DONE=0	# Normal exit. 
# Run as root, of course.

function RU_ROOT {
	if [ "$UID" -ne "$ROOT_UID" ]
	then
		help;
	fi
}

function Dont_Ask {
	echo -e "\e[1m\e[91m[Updating Repos]\e[21m\e[39m";
	sudo apt-get update;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "\e[1m\e[91m[Updating programms]\e[21m\e[39m";
	sudo apt-get upgrade -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "\e[1m\e[91m[Updating system]\e[21m\e[39m";
	sudo apt-get dist-upgrade -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "\e[1m\e[91m[Cleaning up]\e[21m\e[39m";
	sudo apt-get autoremove -y;
	sudo apt-get autoclean -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	exit $E_DONE;
}

function Ask {
        echo -e "\e[1m\e[91m[Updating Repos]\e[21m\e[39m";
        sudo apt-get update;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating programms]\e[21m\e[39m";
        sudo apt-get upgrade;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating system]\e[21m\e[39m";
        sudo apt-get dist-upgrade;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Cleaning up]\e[21m\e[39m";
        sudo apt-get autoremove;
        sudo apt-get autoclean;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        exit $E_DONE;
}

function display_help {
	echo -e "this is a programm to update your system."
	echo -e "";
	echo -e "The programm requires root permitions."
	echo -e "";
	echo -e "$SCRIPT_NAME -[v|h|y|n]"
	echo -e "\t -v \t\t outputs version."
	echo -e "\t -h \t\t play this message"
	echo -e "\t --help \t play this message"
	echo -e "\t -y \t\t do not ask for updates, this is the default usage action"
	echo -e "\t -n \t\t ask for updates"
}

function help {
	display_help
	exit $E_NOTROOT
}

function version {
	echo -e "$SCRIPT_NAME VERSION: $VERSION";
	echo -e "\t CREATOR: $AUTHOR";
        exit $E_NOTROOT
}

if [ $# -gt 0 ];
then
	while [ $# -gt 0 ]
	do
    		case "$1" in
        	-h)
	       		help;
        		exit
        		;;
		--help)
			help;
			exit
			;;        	
		-v)
        		version;
			exit
			;;
		-y)
			RU_ROOT;
			Dont_Ask;
			exit
			;;
		-n)
        		RU_ROOT;
			Ask;
			exit
	        	;;
		*)
			help;
			exit
			;;
    		esac
		shift
	done
else
        RU_ROOT;
        Dont_Ask;
fi


