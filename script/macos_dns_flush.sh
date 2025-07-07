#!/bin/bash

# <username> ALL = NOPASSWD: /usr/bin/pmset
# <username> ALL=(root) NOPASSWD: /usr/bin/pmset
# <username> ALL=(root) NOPASSWD: /usr/bin/dscacheutil -flushcache
# <username> ALL=(root) NOPASSWD: /usr/bin/killall -HUP mDNSResponder

sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

