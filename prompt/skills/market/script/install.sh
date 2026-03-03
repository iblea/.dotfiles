#!/bin/bash

curpath=$(dirname "$(realpath $0)")
cd "$curpath"

VENV_NAME="venv_market"

if [ ! -d "$VENV_NAME" ]; then
	python3 venv "$VENV_NAME"
fi

source ./$VENV_NAME/bin/activate
pip3 install -r requirements.txt
deactivate
