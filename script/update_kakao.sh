#!/bin/bash

process=$(ps -aef | grep "KakaoTalk" | grep -v "grep")
echo "$process"

if [ "$process" != "" ]; then
    echo "process is running. please shutdown process first."
    exit 0
fi

test -d /Applications/KakaoTalkDev.app && rm -rf /Applications/KakaoTalkDev.app
test -d /Applications/DuelKakaoTalk.app && rm -rf /Applications/DuelKakaoTalk.app
echo "remove old Duel KakaoTalk"

cp -a /Applications/KakaoTalk.app /Applications/KakaoTalkDev.app
echo "copy KakaoTalk to KakaoTalkDev"

mv /Applications/KakaoTalkDev.app/contents/MacOS/KakaoTalk /Applications/KakaoTalkDev.app/Contents/MacOS/KakaoTalkDev
echo "binary name change"

cd /Applications/KakaoTalkDev.app/Contents/
/usr/bin/sed -i .bak "s/KakaoTalk<\/string>/KakaoTalkDev<\/string>/g" Info.plist
/usr/bin/sed -i .bak "s/com.kakao.KakaoTalkMac<\/string>/com.kakao.KakaoTalkDevMac<\/string>/g" Info.plist
echo "plist change"

codesign --force --deep --sign - /Applications/KakaoTalkDev.app
echo "app signing done"

mv /Applications/KakaoTalkDev.app /Applications/DuelKakaoTalk.app
echo "Done! (/Application/DuelKakaoTalk.app)"

open /Applications/DuelKakaoTalk.app