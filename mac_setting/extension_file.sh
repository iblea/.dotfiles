#!/bin/bash

change_prog_name="com.apple.automator.gvim"

change_extensions=(
    "com.apple.log"
    "public.data"
    "public.plain-text"
)

for change_extension in "${change_extensions[@]}"; do
    echo "change : $change_extension"
    defaults write com.apple.LaunchServices/com.apple.launchservices.secure \
      LSHandlers -array-add \
      "{LSHandlerContentType=${change_extension};LSHandlerRoleAll=${change_prog_name};}"

done


exit 0

plutil -convert xml1 $HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist

echo "$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"

plutil -convert binary1 $HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
