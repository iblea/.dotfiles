#!/bin/bash
export SSLKEYLOGFILE="/Users/$USER/sslkeylog.log"

# open -a /Applications/Arc.app/Contents/MacOS/Arc --args --ssl-key-log-file="$SSLKEYLOGFILE"
# open -n -a /Applications/Arc.app/Contents/MacOS/Arc --args --ssl-key-log-file="$SSLKEYLOGFILE"
# open -n -a /Applications/Arc.app --args --ssl-key-log-file="$SSLKEYLOGFILE"

open -a /Applications/Arc.app --args --ssl-key-log-file="$SSLKEYLOGFILE"
