#!/bin/sh

# check_disk_space.sh
#
# Description:
# Checks for available disk space and sends warning (via email) if below
# urgent/critical thresholds. For use on outdated servers that weren't properly
# maintained by previous 'owners' that are running on legacy/end-of-life
# operating system(s). On a properly maintained system, there are far more
# elegant ways to monitor disk space. The author(s) recommend you use those
# other methods instead of this software if/where at all possible.
# 
# Usage: Install to location of your choice and setup a cronjob as root.
#
# Example: 00  12  *  *  * /root/sbin/check_disk_space.sh
#
# Author     : Omar Asfour <dev@omar.asfour.ca> https://omar.asfour.ca
# License    : CC0 1.0 Universal (CC0 1.0) - Public Domain Dedication
# License URL: http://creativecommons.org/publicdomain/zero/1.0/
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide.
#
# This software is distributed without any warranty. You should have received a
# copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
#

### CONFIGURATION ###
urgent=2048     # urgent threshold (in MiB - Mebibytes available))
critical=1024   # critical threshold

mailhost=10.0.0.2
mailport=25
fromname="Server"
fromaddr=server@example.org
toname="recipient"
toaddr=recipient@somewhere.org

### SUPPORTING FUNCTIONS  ###

# Checks last status line returned by server.
# By default, expects '250' status; but can be invoked
# to check for other status codes
# eg. checkStatus "${sts}" "${line}" 220
function checkStatus {
  expect=250
  if [ $# -eq 3 ] ; then
    expect="${3}"
  fi
  if [ $1 -ne $expect ] ; then
    echo "Error: ${2}"
    exit
  fi
}

# Establishes connection to server and sends message
# Parameters:
#   $1 = status (string)
#   $2 = space_available (integer)
# eg. sendWarning 'critical' 1234
function sendWarning {
   msgdate=$(date +"%a, %d %b %Y %T %z")
   msgstatus=$(echo "$1" | tr '[:lower:]' '[:upper:]')
   subject="Server Disk Space $msgstatus"
   message="Disk space $1: $2 MiB"

   # Open TCP/UDP Socket using file-descriptor '3'
   exec 3<>/dev/tcp/${mailhost}/${mailport}

   # Connect to SMTP Server
   read -u 3 sts line
   checkStatus "${sts}" "${line}" 220
   echo "HELO ${mailhost}" >&3

   read -u 3 sts line
   checkStatus "$sts" "$line"
   echo "MAIL FROM: <${fromaddr}>" >&3

   read -u 3 sts line
   checkStatus "$sts" "$line"
   echo "RCPT TO: <${toaddr}>" >&3

   read -u 3 sts line
   checkStatus "$sts" "$line"
   echo "DATA" >&3

   read -u 3 sts line
   checkStatus "${sts}" "${line}" 354

   # Send Payload (message)
   echo "Date: $msgdate" >&3
   echo "From: $fromname <$fromaddr>" >&3
   echo "To: $toname <$toaddr>" >&3
   echo "Subject: $subject" >&3
   echo "$message" >&3
   echo "." >&3

   # Confirm Success & Quit
   read -u 3 sts line
   checkStatus "$sts" "$line"
   echo "QUIT" >&3

  # Confirm Quit(ted) successfully -- Not really necessary
   read -u 3 sts line
   checkStatus "${sts}" "${line}" 221
}

### MAIN (script entry point) ###

# Get available MiB on / mount-point
available=`df -m | grep '/$' | awk '{print $3}'`

# Compare avaialble disk space against thresholds and
# send warning if below threshold
if [[ $available -lt $critical ]]; then
   sendWarning 'critical' $available
elif [[ $available -lt $urgent ]]; then
   sendWarning 'urgent' $available
fi