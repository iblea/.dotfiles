#!/bin/bash



sudo mdutil -a -i off
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

# sudo mdutil -s /
# sudo mdutil -a -s
# sudo mdutil -a -i off
# sudo mdutil -E /
# sudo mdutil -a -i on
