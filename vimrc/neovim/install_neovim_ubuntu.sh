#!/bin/bash

sudo add-apt-repository ppa:neovim-ppa/stable 
sudo apt-get update
sudo apt-get install neovim


# tree-sitter 바이너리 설치가 필수가 됨.
which tree-sitter
# npm install tree-sitter-cli
