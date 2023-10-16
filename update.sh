#!/bin/bash
# ------------------------------------------------------------------
# [Spaniakos] Update script
#          The script updates the system.
# ------------------------------------------------------------------
SCRIPT_NAME="$0"
VERSION="1.0"
AUTHOR="G.Spanos - gspanos@makeasite.gr"
CREATE_DATE="2/9/2016"
LAST_UPDATE="16/10/2023"

ROOT_UID=0	# Only users with $UID 0 have root privileges.
E_NOTROOT=87	# Non-root exit error.
E_DONE=0	# Normal exit. 
# Run as root, of course.

# $1 : Username
# $2 : Command `command`
function run_as_user() {
	#test if running bash as a different user works
	sudo -i -u $1 bash << EOF
	$2
EOF
}

function RU_ROOT {
	if [ "$UID" -ne "$ROOT_UID" ]
	then
		help;
	fi
}

function Dont_Ask {
	echo -e "\e[1m\e[91m[Updating Repos]\e[21m\e[39m";
	apt-get update;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "\e[1m\e[91m[Updating programms]\e[21m\e[39m";
	apt-get upgrade -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "\e[1m\e[91m[Updating system]\e[21m\e[39m";
	apt-get dist-upgrade -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "\e[1m\e[91m[Cleaning up]\e[21m\e[39m";
	apt-get autoremove -y;
	apt-get autoclean -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating flatpak]\e[21m\e[39m";
	flatpak update;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating rust If available]\e[21m\e[39m";
        run_as_user $1 "rustup update"
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating Composer If available]\e[21m\e[39m";
        composer self-update
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating freshclam (clamAV) If available]\e[21m\e[39m";
        freshclam
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	exit $E_DONE;
}

function Ask {
        echo -e "\e[1m\e[91m[Updating Repos]\e[21m\e[39m";
        apt-get update;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating programms]\e[21m\e[39m";
        apt-get upgrade;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating system]\e[21m\e[39m";
        apt-get dist-upgrade;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Cleaning up]\e[21m\e[39m";
        apt-get autoremove;
        apt-get autoclean;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating flatpak]\e[21m\e[39m";
	flatpak update;
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating rust If available]\e[21m\e[39m";
	run_as_user $1 "rustup update"
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating Composer If available]\e[21m\e[39m";
        composer self-update
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        echo -e "\e[1m\e[91m[Updating freshclam (clamAV) If available]\e[21m\e[39m";
        freshclam
        echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
        exit $E_DONE;
}

function display_help {
	echo -e "this is a programm to update your system."
	echo -e "";
	echo -e "The programm requires root permitions."
	echo -e "";
	echo -e "$SCRIPT_NAME -[v|h|y|n|u]"
	echo -e "\t -v \t\t outputs version."
	echo -e "\t -h \t\t play this message"
	echo -e "\t --help \t play this message"
	echo -e "\t -u <username> \t\t Specific user name to run some commands like rustup"
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

userset=0;
user="root";
y=0
while getopts ":h:v:y:n:u:-help:" opt; do
	case $opt in
		h)
			help;
			exit
			;;
		v)
			version;
			exit
			;;
		y)
			y=1;
			;;
		n)
			y=0;
			;;
		u)
			userset=1;
			user="$OPTARG"
			;;
		-help)
			help;
			exit
			;;
		\?) echo "Invalid option -$OPTARG" >&2
			exit 1
			;;
	esac

	case $OPTARG in
		h) ;;
		v) ;;
		y) ;;
		n) ;;
		u) ;;
		--help)
			help;
			exit
			;;
		-*) echo "Option $opt needs a valid argument"
			exit 1
			;;
	esac
done

if [ $userset -eq 0 ];
then
	echo -e "\e[1m\e[91m\t***User is set to root! There are command that are user level specific and might not run as expected!***\e[21m\e[39m";
fi

if [ $# -eq 0 ];
then
	RU_ROOT;
	Dont_Ask $user;
else
	if [ $y -eq 0 ];
	then
		RU_ROOT;
		Ask $user;
	else
		RU_ROOT;
		Dont_Ask $user;
	fi
fi
