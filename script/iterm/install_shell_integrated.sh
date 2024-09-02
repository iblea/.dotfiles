#!/bin/bash

curpath=$(dirname "$(realpath $0)")
cd "$curpath"


curl -sL https://iterm2.com/shell_integration/bash \
-o "${curpath}/iterm2_shell_integration.bash"

curl -sL https://iterm2.com/shell_integration/zsh \
-o "${curpath}/iterm2_shell_integration.zsh"

