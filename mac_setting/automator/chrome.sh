export SSLKEYLOGFILE="/Users/$USER/sslkeylog.log"

# open -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --ssl-key-log-file="$SSLKEYLOGFILE"
# open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --ssl-key-log-file="$SSLKEYLOGFILE"
open -a /Applications/Google\ Chrome.app --args --ssl-key-log-file="$SSLKEYLOGFILE"
# open -n -a /Applications/Google\ Chrome.app --args --ssl-key-log-file="$SSLKEYLOGFILE"
