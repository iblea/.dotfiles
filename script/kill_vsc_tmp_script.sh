#!/bin/bash

# git size
# git 커밋 사이즈 계산
# git diff --cached --numstat  | awk '{ plus+=$1; minus+=$2; } END { sum = plus + minus; printf sum; }'

echo "before kill vscode process"
ps -aef | grep vscode

pkill -f vscode
pkill -f vscode
pkill -f vscode
pkill -f vscode
pkill -f vscode

sleep 1

while true
do
    ps_vscode=\$(ps -ef | grep "vscode" | grep -v ".*\sgrep\s.*vscode.*" | awk -F ' ' '{ print \$2 }' | head -n 1)
    if [ -z "\$ps_vscode" ]; then
        break
    fi
    kill -9 \$ps_vscode
done

echo "after kill vscode process"
ps -aef | grep vscode


cd $HOME/.dotfiles/script/
if [ "\$1" = "1" ]; then
    curpath=\$(dirname "\$(realpath \$0)")
    cd "\$curpath"
    rm -rf ./kill_vsc_tmp_script.sh
else
    sleep 2
    nohup /bin/bash ./kill_vsc_tmp_script.sh 1 1>/dev/null 2>&1 &
fi

