#!/bin/bash

curpath=$(readlink -e $(dirname "$0"))
cd "$curpath"

npm install --ignore-scripts
