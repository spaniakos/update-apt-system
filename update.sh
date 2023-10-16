#!/bin/bash
# ------------------------------------------------------------------
# [SCRIPT_NAME] update.sh
# [VERSION] 1.1.2
# [AUTHOR] G.Spanos - gspanos@makeasite.gr - spaniakos@gmail.com - spaniakos - drvs
# [CREATE_DATE] 2/9/2016 [DD/MM/YYYY]
# [LAST_UPDATE] 16/10/2023 [DD/MM/YYYY]
# ------------------------------------------------------------------
# This script updates the apt system and various manual packages and commands.
# It can be used to update the system without asking for confirmation or by asking for confirmation.
# ------------------------------------------------------------------

SCRIPT_NAME="$0"
VERSION="1.1.1"
AUTHOR="G.Spanos - gspanos@makeasite.gr - spaniakos@gmail.com - spaniakos - drvs"
CREATE_DATE="2/9/2016"
LAST_UPDATE="16/10/2023"

ROOT_UID=0	# Only users with $UID 0 have root privileges.
E_NOTROOT=87	# Non-root exit error.
E_DONE=0	# Normal exit. No errors.

# This function runs a command as a specified user.
# $1 : Username
# $2 : Command `command`
function run_as_user() {
	#test if running bash as a different user works
	sudo -i -u $1 bash << EOF
	$2
EOF
}

# This function checks if the user running the script is the root user.
# If not, it calls the help function.
function RU_ROOT {
	if [ "$UID" -ne "$ROOT_UID" ]
	then
		help;
	fi
}

# Function to check if a package is installed and return true or false
# 
# Arguments:
#   $1: package name
#
# Returns:
#   0 if package is installed, 1 otherwise
function is_package_installed {
	if dpkg -s $1 >/dev/null 2>&1; then
		return 0;
	else
		return 1;
	fi
}

# Function to check if a command is installed and return true or false
# 
# Arguments:
#   $1: command name
#
# Returns:
#   0 if command is installed, 1 otherwise
function is_command_installed {
	if command -v $1 >/dev/null 2>&1; then
		return 0;
	else
		return 1;
	fi
}

# This function updates the system without asking for confirmation by updating the repositories, upgrading the installed programs, 
# upgrading the system, cleaning up the system, and updating additional packages such as flatpak, snap, 
# rust, composer, and freshclam (clamAV) if they are installed.
# It also prints the start and end time of the update process.
# Parameters:
# $1 - The user to run rustup update as (if rustup is installed)
function Update_Without_Asking {
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	echo -e "\e[1m\e[92m[Update starting]: $current_date_time\e[21m\e[39m";
	
	# Update repositories
	echo -e "\e[1m\e[91m[Updating Repos]\e[21m\e[39m";
	apt-get update;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Upgrade installed programs
	echo -e "\e[1m\e[91m[Updating programms]\e[21m\e[39m";
	apt-get upgrade -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Upgrade the system
	echo -e "\e[1m\e[91m[Updating system]\e[21m\e[39m";
	apt-get dist-upgrade -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Clean up the system
	echo -e "\e[1m\e[91m[Cleaning up]\e[21m\e[39m";
	apt-get autoremove -y;
	apt-get autoclean -y;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Check if flatpak is installed and update it if available
	if is_package_installed flatpak; then
		echo -e "\e[1m\e[91m[Updating flatpak If available]\e[21m\e[39m";
		flatpak update -y;
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if snap is installed and update it if available
	if is_package_installed snap; then
		echo -e "\e[1m\e[91m[Updating snap]\e[21m\e[39m";
		snap refresh;
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if rust command is installed and update it if available
	if is_command_installed rustup; then
		echo -e "\e[1m\e[91m[Updating rust If available]\e[21m\e[39m";
		run_as_user $1 "rustup update"
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if composer command is installed and update it if available
	if is_command_installed composer; then
		echo -e "\e[1m\e[91m[Updating Composer If available]\e[21m\e[39m";
		composer self-update
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if freshclam command is installed and update it if available
	if is_command_installed freshclam; then
		echo -e "\e[1m\e[91m[Updating freshclam (clamAV) If available]\e[21m\e[39m";
		freshclam
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	end_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	echo -e "\e[1m\e[92m[Update finished]: $end_date_time\e[21m\e[39m";
	exit $E_DONE;
}

# This function updates the system by updating the repositories, upgrading the installed programs, 
# upgrading the system, cleaning up the system, and updating additional packages such as flatpak, snap, 
# rust, composer, and freshclam (clamAV) if they are installed.
# It also prints the start and end time of the update process.
# Parameters:
# $1 - The user to run rustup update as (if rustup is installed)
function Update_With_Asking {
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	echo -e "\e[1m\e[92m[Update starting]: $current_date_time\e[21m\e[39m";
	
	# Update repositories
	echo -e "\e[1m\e[91m[Updating Repos]\e[21m\e[39m";
	apt-get update;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Upgrade installed programs
	echo -e "\e[1m\e[91m[Updating programms]\e[21m\e[39m";
	apt-get upgrade;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Upgrade the system
	echo -e "\e[1m\e[91m[Updating system]\e[21m\e[39m";
	apt-get dist-upgrade;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Clean up the system
	echo -e "\e[1m\e[91m[Cleaning up]\e[21m\e[39m";
	apt-get autoremove;
	apt-get autoclean;
	echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
	echo -e "";
	
	# Check if flatpak is installed and update it if available
	if is_package_installed flatpak; then
		echo -e "\e[1m\e[91m[Updating flatpak If available]\e[21m\e[39m";
		flatpak update;
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if snap is installed and update it if available
	if is_package_installed snap; then
		echo -e "\e[1m\e[91m[Updating snap]\e[21m\e[39m";
		snap refresh;
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if rust command is installed and update it if available
	if is_command_installed rustup; then
		echo -e "\e[1m\e[91m[Updating rust If available]\e[21m\e[39m";
		run_as_user $1 "rustup update"
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if composer command is installed and update it if available
	if is_command_installed composer; then
		echo -e "\e[1m\e[91m[Updating Composer If available]\e[21m\e[39m";
		composer self-update
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	# Check if freshclam command is installed and update it if available
	if is_command_installed freshclam; then
		echo -e "\e[1m\e[91m[Updating freshclam (clamAV) If available]\e[21m\e[39m";
		freshclam
		echo -e "\e[1m\e[92m[DONE]\e[21m\e[39m";
		echo -e "";
	fi
	
	end_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	echo -e "\e[1m\e[92m[Update finished]: $end_date_time\e[21m\e[39m";
	exit $E_DONE;
}

# Function to display help message
function display_help {
	# Display program description
	echo -e "This is a program to update your system."
	echo -e "";

	# Display program requirements
	echo -e "The program requires root permissions."
	echo -e "";

	# Display program usage
	echo -e "$SCRIPT_NAME -[v|h|y|n|u]"
	echo -e "";

	# Display plain parameters
	echo -e "Plain parameters:";
	echo -e "\t -v \t\t outputs version."
	echo -e "\t -h \t\t display this message"
	echo -e "\t -y \t\t do not ask for updates, this is the default usage action"
	echo -e "\t -n \t\t ask for updates"
	echo -e "";

	# Display argument parameters
	echo -e "Argument parameters:";
	echo -e "\t -u <user> \t Specific user name to run some commands like rustup"
	echo -e "";

	# Display double quotes variables
	echo -e "Double quotes variables"
	echo -e "\t --version \t outputs version."
	echo -e "\t --help \t display this message"
}

# This function displays help information and exits the script with a non-zero exit code.
function help {
	display_help
	exit $E_NOTROOT
}

# This function displays the version information of the script.
# It includes the script name, version number, author, and last update date.
# It also exits the script with a non-zero status code.
function version {
	echo -e "$SCRIPT_NAME";
	echo -e "\tVERSION: $VERSION";
	echo -e "\tCREATOR: $AUTHOR";
	echo -e "\tLast Update $LAST_UPDATE";
        exit $E_NOTROOT
}

userset=0;
user="root";
y=0
while getopts "hvynu: --long help,version" opt; do
	case $opt in
		h | --help)
			help;
			exit $E_DONE;
			;;
		v | --version)
			version;
			exit $E_DONE;
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
		\?) echo -e "\e[1m\e[91mInvalid option! \e[21m\e[39m">&2
			echo -e "\e[1m\e[91mUSAGE: \e[21m\e[39m">&2
			help;
			exit $E_DONE;
			;;
		: ) echo -e "\e[1m\e[91moption -$OPTARG requires an argument \e[21m\e[39m">&2
			exit $E_DONE;
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
	Update_Without_Asking $user;
else
	if [ $y -eq 0 ];
	then
		RU_ROOT;
		Update_With_Asking $user;
	else
		RU_ROOT;
		Update_Without_Asking $user;
	fi
fi
