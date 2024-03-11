#!/bin/bash
################################################################################
# ipdiffmail.sh - IP Address Change Email Notifier
#
# Author: Omar Asfour <http://omar.asfour.ca>
# Release Date: 2013-12-19
# Version: 0.0.1
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>
################################################################################
# Purpose: Check for a change of your external IP address, and send you an
#          email in the event of a change.
#
# WARNING! This script will contain your email login info. Lock it down.
# 
# Dependency: cURL <http://curl.haxx.se/>
# Dependency: SendEMail <http://caspian.dotconf.net/menu/Software/SendEmail/>
#
# Requirement: SMTP/TLS server
# Requirement: user write permission to path of $IPDIFFCURR (default /root/tmp)
# Requirement: user execute permission on /bin/hostname
#
# Exit 0: IP Address not changed
# Exit 1: IP Address changed ; SendEmail invoked (ie. check your inbox)
################################################################################
# Usage Notes:
#  
# To have this run every 12 hrs on the 30 min mark, and log only changes 
# (stderr) to syslog, add the following to **crontab** (5), substituting [user]
# for the file owner, and [path] with the path to this script:
#
# 30 */12 * * * [user] ([path]/ipdiff.sh > /dev/null) 2>&1 | logger -i -t IPDIFF
#
################################################################################
DEBUG=0                                     # Set to 1 for debug mode
IPDIFFCURR='/root/tmp/ipdiff.curr'          # Tracks current/last-known IP
SENDERNAME=`/bin/hostname`                  # Sender (ie. From: in email)
SMTPSERVER='smtp.yourserver.com:587'        # SMTP/TLS server:port
 
# Modify these to match your Gmail account.
RECEIVERNAME='Your Name'                    # Your name
SMTPUSER='yoursmtpaccount'                  # Your SMTP/TLS account
SMTPPASS='y0urp@sswd'                       # Your SMTP/TLS password
 
# Sends notification email and updates record of current IP Address
function change_execute {
    MSGBODY="$SENDERNAME IP Address changed: $CURRIP $NEWIP"
    `/usr/bin/sendemail -s $SMTPSERVER -f "$SENDERNAME <$SMTPUSER>" -t "$RECEIVERNAME <$SMTPUSER>" -u $MSGBODY -m $MSGBODY -o tls=yes -o username=$SMTPUSER -o password=$SMTPPASS`
    echo $NEWIP > $IPDIFFCURR
}
 
# IP Address has changed. Call change_execute, and write message to 'standard error', exit in 'error' state.
function change_exit {
    change_execute
    echo "$1" 1>&2
    exit 1
}
 
# IP Address has not changed. Write message to 'standard output' and exit in 'success' state.
function nochange_exit {
    echo "$1"
    exit 0
}
 
# Checks for IP Address change, relying on opendns.com for answers
function ipchange_check {
    NEWIP=`nslookup -query=a myip.opendns.com resolver1.opendns.com | awk -F': ' 'NR==6 {print $2}'`
    if [ $DEBUG -gt 0 ]; then echo "\$NEWIP=$NEWIP"; fi
    if [ $DEBUG -gt 0 ]; then echo "\$CURRIP=$CURRIP"; fi
	if [ $NEWIP != $CURRIP ]; then
	    change_exit "IP Address changed: $CURRIP $NEWIP"
	else
		nochange_exit "IP Address unchanged: $CURRIP/$NEWIP"
	fi
}
 
# MAIN (Script Entry Point)
if [ -f $IPDIFFCURR ]; then
    CURRIP=`cat $IPDIFFCURR`
    ipchange_check
else
    CURRIP='0.0.0.0'
    ipchange_check
fi