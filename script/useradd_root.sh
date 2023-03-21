#!/bin/bash

USERNAME=usertest
PASSWORD="test1212!"
SHELL_PATH=/bin/bash


is_exist=`cat /etc/passwd | grep "^$USERNAME:"`
if [[ $is_exist != "" ]]; then
	echo "user name exist"
	exit
fi

HOME_PATH=/home/$USERNAME
if [ ! -d $HOME_PATH ]; then
	mkdir $HOME_PATH
else
	echo "home directory exist"
fi
# useradd
useradd $USERNAME -d $HOME_PATH

# /etc/passwd change
sed -i "s#^$USERNAME:x:.*#$USERNAME:x:0:0::$HOME_PATH:$SHELL_PATH#" /etc/passwd

# /etc/group change
sed -i "s#^$USERNAME:x:.*#$USERNAME:x:0:#" /etc/group

# password setting
yes $PASSWORD | passwd $USERNAME
