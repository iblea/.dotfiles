#!/bin/bash

curpath=$(readlink -e $(dirname "$0"))

SCRIPT_NAME="convert.js"

node "$curpath/$SCRIPT_NAME" $@ 2>&1

