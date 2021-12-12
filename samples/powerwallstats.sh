#!/bin/bash


#######################################################
# Release Notes:
#
# Powerwall stats dumper for openhab
# Created by Vince Loschiavo - 2021-02-21
# As of Tesla Powerwall version 20.49.0, the powerwall gateway requires you authenticate for every stat.
#
# This script will login to the powerwall once per day to refresh the cookie, grab the JSON output from the powerwall and 
#  send it to STDOUT for parsing by your tool of choice.
#
# Example URLs: 
# /api/meters/aggregates
# /api/system_status/soe
# /api/system_status/grid_status
# /api/sitemaster
# /api/powerwalls
# /api/status
#
#
#######################################################
# Usage:
# ./powerwallstats.sh /URL/YOU/WANT/TO/COLLECT
#
# eg:
# ./powerwallstats.sh /api/meters/aggregates
#######################################################



#######################################################
# User Modified Variables
#######################################################
# You'll want to change these to match your environment

POWERWALLIP="powerwall"			# This is your Powerwall IP or DNS Name
PASSWORD='Y0ur$up3r$3cr3tPassword!'	# Login to the Powerwall UI and Set this password - follow the on-screen instructions



#######################################################
# Static Definitions
#######################################################
# You probably won't need to change these

TOKEN_REFRESH=86400			# How often to re-login to refresh the token in seconds (86400 = 1 day)
USERNAME="customer"
EMAIL="Lt.Dan@bubbagump.com"		# Set this to whatever you want, it's not actually used in the login process; I suspect Tesla will collect this eventually
COOKIE="/tmp/PWcookie.txt"		# Feel free to change this location as you see fit.  
URL=$1





#######################################################
# Subroutines
#######################################################

# Create a valid Cookie
create_cookie () {
	# Delete the old cookie if it exists
	if [ -f $COOKIE ]; then 
		rm -f $COOKIE
	fi
	
	# Login and Create new cookie
	result=$(curl -s -k -c $COOKIE -X POST -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\", \"email\":\"$EMAIL\",\"force_sm_off\":false}" "https://$POWERWALLIP/api/login/Basic")

	# If Login fails, then throw error and exit
	if ! grep -q AuthCookie $COOKIE; then
		rm -f $COOKIE
		echo "Login failed: $result"
		exit 1
	fi
}


# Check for a valid cookie
valid_cookie () {

	# if cookie doesnt exist, then login and create the cookie
	if [ ! -f $COOKIE ]; then
  		# Cookie not present. Creating cookie.
		create_cookie
	fi

	# If the cookie is older than the refresh interval, refresh the cookie
	# Collect both times in seconds-since-the-epoch
	NOW_TIME=$(date +%s)
	FILE_TIME=$(date -r "$COOKIE" +%s)
	FILE_AGE=$[NOW_TIME - FILE_TIME]

	if [ "$FILE_AGE" -ge "$TOKEN_REFRESH" ]; then
		#The cookie is older than refresh interval; get a new cookie
		create_cookie
	fi
}


getstat () {
	curl -s -S -k -b $COOKIE https://$POWERWALLIP$URL
}




#######################################################
# Main
#######################################################

# Check for a valid cookie or login and create one
valid_cookie

# Get URL like /api/meters/aggregates
getstat

#Done
