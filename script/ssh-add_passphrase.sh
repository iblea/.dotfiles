#!/bin/bash


if [ -z "$(command -v ssh-agent)" ]; then
	echo "no ssh-agent"
	exit 1
fi

if [ -z "$(command -v ssh-add)" ]; then
	echo "no ssh-add"
	exit 1
fi


eval `ssh-agent -s`
ssh-add $HOME/.ssh/id_rsa

