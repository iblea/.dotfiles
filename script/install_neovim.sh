#!/bin/bash


# apt-get update
# apt-get install neovim
# apt-get purge neovim
# apt-get remove neovim


apt-get update && apt-get install -y ninja-build gettext make cmake curl build-essential jq


git clone https://github.com/neovim/neovim.git
cd neovim
git checkout v0.11.6
make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/opt/nvim
RET_CODE="$?"
if [ $RET_CODE -ne 0 ]; then
    echo "compile failed... [$RET_CODE]"
    exit $RET_CODE
fi

mkdir -p /opt/nvim
make install

if [ -f "/opt/nvim/bin/nvim" ]; then
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
    ln -s /opt/nvim/lib/nvim /usr/local/lib/nvim
    ln -s /opt/nvim/share/nvim /usr/local/share/nvim

    cd ../
    rm -rf neovim

    echo "neovim compile done"
    nvim --version
fi


if [ -z "$(command -v node)" ]; then

    echo -n "not found nodejs. install nodejs? [y/n]: "
    read answer
    if [[ ! "$answer" =~ ^[yY](es)?$ ]]; then
        echo "nodejs install cancelled."
        echo "you should install tree-sitter-cli."
        exit 1
    fi
    echo -n "input nodejs version to install (18/20/22/24... default: 22): "
    read version
    NODE_MAJOR=${version:-22}

    apt-get update
    apt-get install -y ca-certificates curl gnupg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    unset NODE_MAJOR

    apt-get update
    apt-get install -y nodejs

    npm install -g tree-sitter-cli

fi


