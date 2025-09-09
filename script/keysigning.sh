#!/bin/bash

# 사용법

# 상대방의 키 정보와 메일 정보가 입력되어 있는 파일의 경로를 입력합니다.
# 메일 전송 유무를 선택할 수 있습니다.
# ./keysigning.sh "<KEYFILE>" "<MY_KEY>"


# 메일 전송 유무 (0: 메일 전송 안함, 1: 메일 전송 함)
GMAIL_SEND=1
# gmail을 사용할 경우 다음 정보를 입력하면, 알아서 메일을 보내줍니다.
MAIL_FROM="test@test.com"
# gmail 유저명
MAIL_SMTP_USER="gmail_username (google id)"
# 메일 전송 패스워드 (계정 > 보안 > 앱 비밀번호 에서 생성합니다.)
MAIL_SMTP_PASS="abcd efgh ijkl mnop"


# key file은 아래와 같은 포맷을 따릅니다.
# 상대방의_FINGERPRINT 상대방의_EMAIL
# GMAIL_SEND=0 일 때에는 FINGERPRINT만 입력하면 됩니다.
KEYFILE="$1"
# 자신의 서명키 또는 FINGERPRINT 를 입력합니다.
MY_KEY="$2"








# curpath=$(dirname "$(realpath $0)")
# cd "$curpath"

if [ $# -ne 2 ]; then
    echo "Usage: $0 <KEYFILE> <MY_KEY>"
    exit 1
fi

# 파일 내용을 배열로 저장 (각 줄이 하나의 요소)
KEY_FILE_ARRAY=()
while IFS= read -r line; do
    KEY_FILE_ARRAY+=("$line")
done < "$KEYFILE"


curpath=$(dirname "$(realpath $0)")
cd "$curpath"

if [ ! -d "$curpath/gpgkeys" ]; then
    mkdir -p "$curpath/gpgkeys"
fi

function send_mail_with_curl() {
    if [ $GMAIL_SEND -eq 0 ]; then
        return 0
    fi

    local FINGERPRINT="$1"
    local MAIL_TO="$2"
    # echo "FINGERPRINT: $FINGERPRINT"
    # echo "MAIL_TO: $MAIL_TO"

    # 메일 내용을 임시 파일에 저장
    cat > /tmp/mail.txt <<EOF
From: $MAIL_FROM
To: $MAIL_TO
Subject: Your signed PGP key $FINGERPRINT
Content-Type: multipart/mixed; boundary="keysigningbd"

--keysigningbd
Content-Type: text/plain; charset=UTF-8

안녕하세요,
서명된 PGP 키 정보를 첨부합니다.
signedkey.asc 파일이 실제 서명된 공개키 데이터 이오니 참고 바랍니다.
감사합니다.

Fingerprint: $FINGERPRINT
Signed by: $MY_KEY

--keysigningbd
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="signedkey.asc"
Content-Transfer-Encoding: base64

$(cat "$curpath/gpgkeys/${FINGERPRINT}_signedkey.asc" | base64 -w 0)

--keysigningbd
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="msg.asc"
Content-Transfer-Encoding: base64

$(cat "$curpath/gpgkeys/${FINGERPRINT}_msg.asc" | base64 -w 0)

--keysigningbd--
EOF

    if [ ! -f /tmp/mail.txt ]; then
        echo "ERROR: 메일 내용을 임시 파일에 저장하지 못했습니다."
        return 1
    fi

    # \r\n 으로 변환
    sed -i 's/$/\r/' /tmp/mail.txt

    # curl을 사용한 SMTP 전송
    curl --url 'smtp://smtp.gmail.com:587' \
        --verbose \
        --tcp-nodelay \
        --no-buffer \
        --keepalive-time 2 \
        --limit-rate 0 \
        --max-time 300 \
        --ssl-reqd \
        --mail-from "$MAIL_FROM" \
        --mail-rcpt "$MAIL_TO" \
        --user "$MAIL_SMTP_USER:$MAIL_SMTP_PASS" \
        --upload-file /tmp/mail.txt

    curl_exit_code=$?
    /bin/rm -f /tmp/mail.txt

    if [ $curl_exit_code -eq 0 ]; then
        echo "SUCCESS: 메일 전송 성공 <$MAIL_FROM> -> <$MAIL_TO>"
    else
        echo "ERROR: 메일 전송 실패 <$MAIL_FROM> -> <$MAIL_TO> (종료 코드: $curl_exit_code)"
        echo "   - SMTP 인증 정보와 서버 설정을 다시 확인하세요"
        return $curl_exit_code
    fi
    return 0
}

# send_mail_with_curl "test" "test@test.com"
# exit 0


FINGERPRINT=""
MAIL_TO=""

# https://github.com/ubuntu-kr/ksp-toolkits/blob/master/sign-and-send-key.md
# 배열의 각 줄을 순회
for line in "${KEY_FILE_ARRAY[@]}"; do

    if [ -z "$line" ] || [ "${line:0:1}" == "#" ]; then
        continue
    fi

    if [ $GMAIL_SEND -eq 0 ]; then
        FINGERPRINT=$line
        echo "서명 중: $FINGERPRINT"
    else
        FINGERPRINT=$(echo "$line" | awk '{print $1}')
        MAIL_TO=$(echo "$line" | awk '{print $2}')
        echo "서명 중: $FINGERPRINT ($MAIL_TO)"
    fi

    echo "FINGERPRINT: $FINGERPRINT"
    echo "MAIL_TO: $MAIL_TO"

    # gpg --local-user <서명에 사용할 본인의 키ID 나 핑거프린트> --sign-key <상대방의 키ID 나 핑거프린트>
    # gpg --local-user "$MY_KEY" --sign-key "$FINGERPRINT"
    gpg --keyserver "keyserver.ubuntu.com" --recv-keys "$FINGERPRINT"
    gpg --local-user "$MY_KEY" --sign-key "$FINGERPRINT"

    # signedkey.asc 파일 생성 (서명된 공개키)
    gpg --armor --export "$FINGERPRINT" > "$curpath/gpgkeys/${FINGERPRINT}_signedkey.asc"
    echo "✅ signedkey.asc 파일 생성: $curpath/gpgkeys/${FINGERPRINT}_signedkey.asc"

    # msg.asc 파일 생성 (서명 확인 메시지)
    echo "PGP Key Signing completed for fingerprint: $FINGERPRINT" | gpg --armor --clearsign --local-user "$MY_KEY" > "$curpath/gpgkeys/${FINGERPRINT}_msg.asc"
    echo "✅ msg.asc 파일 생성: $curpath/gpgkeys/${FINGERPRINT}_msg.asc"

    # send_mail_with_curl "$FINGERPRINT" "$MAIL_TO"
    send_mail_with_curl "$FINGERPRINT" "$MAIL_TO"
done


exit 0
