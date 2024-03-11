#!/bin/bash
################################################################################
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
# NAME: cleanmacfiles
# PURPOSE: Fairly obvious, I'd think. Gets rid of files created by Mac computers
#          that can be a little annoying.
# CAUTION: In some cases, those bothersome Mac files are 'necessary'.
#          For example; do not use this on your Time Machine backups.
#          You'll regret it.
# USAGE: cleanmacfiles.sh [path]
# OPTIONS: path : defaults to current directory
#
# Note: Execution is recursive. Using this will purge files in subdirectories
################################################################################
#
# Finds files Macs love to throw all over network shares and external media
# and destroys them 
function macFilesMustDieIn {
  (for target in {Temporary\ Items,Network\ Trash\ Folder,.{DS_Store,AppleDB,TemporaryItems,AppleDouble,bin,AppleDesktop,Spotlight,Trashes,fseventd,_*}}; do
    find $1 -name "$target" -print0;
  done) | xargs -0 -I {} rm -rvf {}
}

# Command Line Parser
if [ -n "$1" ]; then   # Executes on directory given in first argument
  macFilesMustDieIn $1 
else		       # If no argument given, executes on current working directory
  macFilesMustDieIn .
fi