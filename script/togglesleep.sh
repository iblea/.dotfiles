#!/bin/bash

sleep_stat=$(pmset -g | grep SleepDisabled | awk -F ' ' '{ print $2 }')
#echo "$sleep_stat"

# already sleep off
if [[ "$sleep_stat" = "1" ]]; then
	# change sleep mode on
	sudo pmset -a disablesleep 0;
	sudo pmset -b disablesleep 0;
	sudo pmset -c disablesleep 0;
# already sleep on
elif [[ "$sleep_stat" = "0" ]]; then
	# change sleep mode off
	sudo pmset -a disablesleep 1;
	sudo pmset -b disablesleep 1;
	sudo pmset -c disablesleep 1;
fi

