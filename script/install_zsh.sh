#!/bin/bash


echo "*********************************************************"
echo "user : $USER"
echo "home : $HOME"
echo "*********************************************************"
echo "Press any key to continue..."
read -s -n1
# read -s -n1 -p "Press any key to continue..."

echo "run"

curpath=$(dirname "$(realpath $0)")
cd "$curpath"

if [ ! -d "$HOME/.zsh/" ]; then
    mkdir "$HOME/.zsh"
fi

if [ -d "$HOME/.zsh/.oh-my-zsh/" ]; then
    echo "already install oh-my-zsh"
else
    cd "$HOME"
    curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | /bin/bash - 
    mv "$HOME/.oh-my-zsh/" "$HOME/.zsh/"
fi

echo ""
echo ""
echo ""
echo "oh my zsh install done"
echo ""
echo ""
echo ""

if [ -d "$HOME/.zsh/.oh-my-zsh/custom/themes/powerlevel10k/" ]; then
    echo "already install p10k"
else
    git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "$HOME/.zsh/.oh-my-zsh/custom/themes/powerlevel10k"
fi

if [ -f "$HOME/.zshrc" ]; then
	/bin/rm -f "$HOME/.zshrc"
fi

echo ""
echo ""
echo ""
echo "p10k install done"
echo "execute settings.sh script"
echo ""

