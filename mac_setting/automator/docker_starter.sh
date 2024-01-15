#!/bin/bash

already_docker=$(ps -aef | grep "docker serve .*\.sock" | grep -v "grep")
if [ -n "$already_docker" ]; then
	echo "docker service is already running."
	exit 0
fi

open /Applications/Docker.app

cnt=0
while [ : ] ; do
	if [ $cnt -ge 10 ]; then
		echo "docker start failed"
		exit 1
		# break;
	fi

	cnt=$(expr $cnt + 1)
	sleep 1
	docker_find=$(ps -aef | grep "docker serve .*\.sock" | grep -v "grep")

	if [ -z "$docker_find" ]; then
		echo "cannot find docker process, continue and wait 1 second"
		continue;
	fi

	# Wait until Docker is completely running.
	sleep 5
	echo "docker start"
	docker start volado
	break;
done

echo "done"

