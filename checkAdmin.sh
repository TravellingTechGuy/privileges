#!/bin/bash

# Travelling Tech Guy - 6th of March 2019

# Proof of concept - use at own risk!

# This script is an attempt to add a little enforcement to return to standard privileges when using the SAP privileges app

# The SAP Privileges project page:
# https://github.com/SAP/macOS-enterprise-privileges

# set time limit (set to 5 minutes for testing)

timeLimit="5"

logFile="/usr/local/bin/.lastAdminCheck.txt"
timeStamp=$(date +%s)

# check if file exists

		if [ -f $logFile ]; then
		 
		  echo "File ${logFile} exists."
		
		else
		
		  echo "File ${logFile} does NOT exists"
		  touch $logFile
		  echo $timeStamp > $logFile
		  
		fi	

# grab the logged in user
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

# check if the user is admin

		if [[ $("/usr/sbin/dseditgroup" -o checkmember -m $loggedInUser admin / 2>&1) =~ "yes" ]]; then
  			
  			echo "User is Admin... keeping an eye on him/her!"
  			userType="Admin"
  		
  		else
  			
  			echo "User is not admin... bye bye"
  			userType="Standard"
  			rm $logFile
  			exit
		
		fi
		
# process Admin time

		if [[ $userType = "Admin" ]]; then	

			oldTimeStamp=$(head -1 ${logFile})
			rm $logFile
			touch $logFile
			echo $timeStamp > $logFile

			adminTime=$(($timeStamp - $oldTimeStamp))
			echo "Admin time in seconds: " $adminTime
			
			adminTimeMinutes=$(($adminTime / 60))
			echo "Admin time in minutes: " $adminTimeMinutes

		fi

echo "Time Limit is: " $timeLimit
	
# if user is admin for more than the time limit, ask if to confirm need for superpowers

if [[ "$adminTimeMinutes" -ge $timeLimit ]]; then

confirmAdmin=`/usr/bin/osascript <<EOT
tell application "Finder"
    activate
	set myReply to button returned of (display dialog "Do you still need Admin Super Power?" buttons {"Yes", "No"} default button 2)
end tell
EOT`

fi

# take action

if [[ "$confirmAdmin" == "No" ]]; then
echo "Demoting the user!"
/usr/local/bin/jamf displayMessage -message "OK, Admin rights revoked"

# Demote the user
sudo -u $loggedInUser /Applications/Privileges.app/Contents/Resources/PrivilegesCLI --remove
fi

if [[ "$confirmAdmin" == "Yes" ]]; then
/usr/local/bin/jamf displayMessage -message "OK, but use them wisely you must - Yoda"
fi
