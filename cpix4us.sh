#! /bin/bash

echo 'Hello, daemons! Welcome to the cpix script!'
echo 'The script is now running...'

function main {
	echo "main function running..."

#	begin scripts

	aptf #apt-get update #
	toolbelt #install tools #
	noport #enables ufw
	lockdown #locks accounts #
	nopass #sets password policies
	sshfix #sshconfig #
	nomedia #gets rid of media files #
	rootkits #configures rootkit tools to run weekly
#	scruboff #get rid of software

#	end of scripts

	echo "Script is complete..."
	echo "Begin fishing for points...\n"
	cont
}


# function that pauses between steps
function cont {
	read -n1 -p "Press space to continue, AOK to quit" key
	if [ "$key" = "" ]; then
		echo "Moving forward..."
	else
		echo "Quitting script..."
		exit 1
	fi
}

#apt update
function aptf {
	echo ""
	echo "Updating the system..."

	#offline solution
	cp ./mysources.list /etc/apt/sources.list

	#online solution
#	curl https://repogen.simplylinux.ch/txt/trusty/sources_61c3eb1fcff54480d3fafbec45abfe85c2a4b1a8.txt | tee /etc/apt/sources.list

	apt-get -y update
	apt-get -y upgrade
#	apt-get -y install --reinstall coreutils
	echo "Finished updating"
	cont
}

#install tools to use for misc purposes
function toolbelt {
	echo ""
	echo "Installing Utilities..."
	apt-get -y install \
	bash \
	vim \
	ufw \
	gufw \
	firefox \
	clamav \
	netstat \
	nmap \
	libpam-cracklib \
	lsof \
	locate \
	chkrootkit \
	openssh-server \
	rkhunter
	echo "Finished installs"
	updatedb
	echo "Updated database"
	cont
}

# hardens network security
function noport {
	echo ""
	echo "Enabling Uncomplicated Firewall..."
	ufw enable
	cont

	echo "Hardening IP security..."

	netsecfilea="$(find /etc/sysctl.d/ -maxdepth 1 -type f -name '*network-security.conf')" # finds default net-sec config file
	netsecfile="${netsecfilea// }" # eliminates whitespace from the string (if there is any)
	netsecfileb=$netsecfile"~" # names the backup file

	cp $netsecfile $netsecfileb # creates a backup of the config file
	chmod a-w $netsecfileb # makes backup read-only

	cp /etc/sysctl.conf /etc/sysctl.conf~ # backup sysctl config
	chmod a-w /etc/sysctl.conf~ # read only

	echo "Backups created"

	# 3 cases - found file, no file, multiple files
	#TODO test the line by line method for all cases
	if [ -z $netsecfile ] # true if FIND didn't find anything
	then
		echo "find could not find the file you were looking for, attempting to use sysctl -w"
		# reads from ipsec2 line by line using sysctl command to change settings

		file="./ipsec2.conf"
		while IFS= read -r line
		do
			# reads from ipsec2 line by line and uses sysctl command
			sysctl -w "$line"
		done <"$file"
		sysctl -p

	else
		echo "File was found, appending settings to end of file"
		# if the file exists, we will append our settings from our file

		cat ./ipsec.conf >> "$netsecfile"
		service procps start

	fi
	cont

	echo "Verify rules..."
	ufw status
	cont
	echo "Finished managing rules"
}


#locks root user and home directory
function lockdown {
	echo ""
	echo "Locking root user"
	passwd -l root
	echo "root locked"
	hahahome='HOME'
	chmod 0750 ${!hahahome}
	echo "home directory locked"
	cont
}


#manages password policies
#this should be its own script
function nopass {
	echo ""
	echo "Changing password policies requires manual interaction\n"
	echo "Please open Mr. Silva's checklist for instructions\n"
	echo "Changing password policies requires manual interaction"
	echo "Please open Mr. Silva's checklist for instructions"

	#run cracklib

	#login.defs
	echo "Making a backup login.defs file..."
	cp /etc/login.defs /etc/login.defs~
	chmod a-w /etc/login.defs~
	cont

	echo "Copying local login.defs file..."
	cp ./my_login.defs /etc/login.defs

	#common-password
	echo "Making a backup config file..."
	cp /etc/pam.d/common-password /etc/pam.d/common-password~
	chmod a-w /etc/pam.d/common-password~
	cont

	echo "Copying local common-password file..."
	cp ./my_common-password /etc/pam.d/common-password

	echo 'Password policies configured'
	# done configuring

	# will change pass age for users aready created
	echo "Applying to all users..."
	for i in $(awk -F':' '/\/home.*sh/ { print $1 }' /etc/passwd); do chage -m 3 -M 60 -W 7 $i; done
	echo "Password Policies finished."
	cont
}


#easy point here
function sshfix {
	echo ''
	echo 'Turn off root login settings for ssh'
	echo 'This must be performed manually'
	echo "Making a backup config file..."
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
	chmod a-w /etc/ssh/sshd_config.backup
	cont

#TODO make sure that default config doesn't change after installing openssh-server
	#permitrootlogin
	cp ./sshdconfig /etc/ssh/sshd_config
	cont

	#enables/disables ssh
	service ssh restart
	read -n1 -r -p "Press 1 to turn off ssh, space to continue..." key
	if [ "$key" = '1' ]; then
		service ssh stop
	fi

	echo 'Finished ssh config editing'
	cont
}

#finds and deletes media files
function nomedia {
	echo "Deleting media..."
	find / -name '*.mp3' -type f -delete
	find / -name '*.mov' -type f -delete
	find / -name '*.mp4' -type f -delete
	find / -name '*.avi' -type f -delete
	find / -name '*.mpg' -type f -delete
	find / -name '*.mpeg' -type f -delete
	find / -name '*.flac' -type f -delete
	find / -name '*.m4a' -type f -delete
	find / -name '*.flv' -type f -delete
	find / -name '*.ogg' -type f -delete
	find /home -name '*.gif' -type f -delete
	find /home -name '*.png' -type f -delete
	find /home -name '*.jpg' -type f -delete
	find /home -name '*.jpeg' -type f -delete
	echo "Media deleted"
	cont
}

#TODO
function rootkits {
	echo "Configuring rootkit finders..."
	sed "s/RUN_DAILY.*/RUN_DAILY true/g" /etc/chkrootkit.conf
	sed "s/CRON_DAILY_RUN.*/CRON_DAILY_RUN true/g" /etc/default/rkhunter
	sed "s/CRON_DB_UPDATE.*/CRON_DB_UPDATE true/g" /etc/default/rkhunter
	mv /etc/cron.weekly/rkhunter /etc/cron.weekly/rkhunter_update
	mv /etc/cron.daily/rkhunter /etc/cron.weekly/rkhunter_run
	mv /etc/cron.daily/chkrootkit /etc/cron.weekly/
#	chkrootkit
#	rkhunter
}


#TODO
function scruboff {
	echo ''
	echo 'check for unwanted apps manually'
#	chkrootkit
	freshclam
	clamscan -i -r --remove=yes /
	service --status-all | less
	sudo dpkg --get --selections | less
	netstat -tulpn | grep -i LISTEN | less
	less /etc/rc.local
	crontab -e | less
	echo 'Please remove any unwanted apps NOW'
	read -n1 -r -p "Press space to continue..." key
	if [ "$key" = '' ]; then
		apt-get --purge autoremove
	else
		echo 'Exiting script...'
		exit 1
	fi
	echo 'Finished uninstalling'
}

#actually running the script
unalias -a #Get rid of aliases
echo "unalias -a" >> /root/.bashrc # gets rid of aliases when root
if [ "$(id -u)" != "0" ]; then
	echo "Please run as root"
	exit
else
	main
fi
