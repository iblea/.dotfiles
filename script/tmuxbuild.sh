#!/bin/bash

if [[ "$(uname -s)" = "Darwin" ]]; then

    brew install libevent ncurses utf8proc pkg-config bison

    ./configure --enable-utf8proc --enable-sixel --enable-static \
        PKG_CONFIG_PATH="$(brew --prefix)/lib/pkgconfig"

    # make -j$(sysctl -n hw.ncpu)
    # sudo make install

else

    apt-get install build-essential pkg-config bison \
        libevent-dev libncurses-dev libutf8proc-dev

    ./configure --enable-utf8proc --enable-sixel --enable-static

    # make -j$(nproc)
    # make install

fi

