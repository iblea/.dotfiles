#!/bin/bash

# https://inbox.kr/186
# https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record
# https://developers.cloudflare.com/fundamentals/api/get-started/create-token/

### CloudFlare A Recoard Updater
### DOMAIN : 변경할 도메인 입력
### RECORD_TYPE : 변경 또는 추가할 레코드의 타입 입력
### RECORD : 변경 또는 추가할 레코드 입력
### CHANGED_IP : 변경/추가할 레코드의 IP 입력
### TTL : 120과 2147483647 사이의 값 입력, 1 입력시 자동
### Proxied : true 또는 false 입력
### To force updating, run with -f

CLOUD_FLARE_API_KEY="CLOUDFLARE_API_KEY (https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)"
DOMAIN="domain.com"
RECORD_TYPE="A"
# RECORD_TYPE="TXT"
RECORD="test.domain.com"
CHANGED_IP="192.168.0.1"
TTL=600
Proxied=false
ZN="" # ZONEID 직접입력









if [ $# -le 1 ] || [ $# -ge 4 ]; then
    echo "Wrong Argument"
    echo ""
    echo "Usage ddns_cloudflare.sh \"[RECORD]\" \"[CHANGED_IP]\" \"[RECORD_TYPE] (default A)\""
    echo "Example : ./ddns_cloudflare.sh \"private.test.com\" \"10.0.0.1\""
    echo "Example : ./ddns_cloudflare.sh \"text.test.com\" \"text_test\" \"TXT\""
    echo ""

    exit 1
fi


if [ $# -eq 2 ]; then
    RECORD="$1"
    CHANGED_IP="$2"
    RECORD_TYPE="A"
elif [ $# -eq 0 ]; then
    RECORD="iasdf.com"
    CHANGED_IP="list"
    RECORD_TYPE="A"

    if [ -z "$(which jq)" ]; then
        echo "jq command not found"
        exit 1
    fi
else
    RECORD="$1"
    CHANGED_IP="$2"
    RECORD_TYPE="$3"
fi









# H1="-HX-Auth-Email:$Login_Email"
# H2="-HX-Auth-Key:$Global_API_Key"
# H3="-HContent-Type:application/json"
H1="Authorization: Bearer $CLOUD_FLARE_API_KEY"
H2="Content-Type: application/json"

# verify the API key
# curl -sk --request GET \
#     --url "https://api.cloudflare.com/client/v4/user/tokens/verify" \
#     -H "$H1" -H "$H2"
# exit 0

V4="https://api.cloudflare.com/client/v4/zones"

function getZone() {
    ZN=$(curl -sk --request GET --url "$V4?name=$DOMAIN" \
        -H "$H1" -H "$H2" | grep -Po '(?<="id":")[^"]*' | head -1)
    echo "$ZN"
}
function AID() {
    curl -sk --request GET --url "$V4/$ZN/dns_records?name=$RECORD" \
        -H "$H1" -H "$H2" | grep -Po '(?<="id":")[^"]*' | head -1
}




# get the zone id
if [ -z "$ZN" ]; then
    ZN=$(getZone)
fi

if [ -z "$ZN" ]; then
    echo "Failed to get the ZONE ID"
    exit 1
fi

AIDARY=$(AID)
# echo "AIDARY: $AIDARY"

if [ -n "$AIDARY" ]; then

    if [ $# -eq 0 ]; then

        output=$(curl -sk --request GET \
            --url "$V4/${ZN}/dns_records" \
            -H "$H1" -H "$H2")

        if [ -z "$output" ]; then
            echo "cloudflare api error"
            exit 1
        fi

        success=$(echo "$output" | jq '.success' )
        if [[ "${success}" = "false" ]]; then
            echo "$output"
            echo "cloudflare api error"
            exit 1
        fi

        output_len=$(echo "$output" | jq '.result | length')
        if [[ "${output_len}" = "0" ]]; then
            echo "$output"
            echo "not found"
            exit 1
        fi

        for (( i=0; i<$output_len; i++ )); do
            idx_content=$(echo "${output}" | jq ".result[$i]")
            # echo "${idx_content}"
            name=$(echo "${idx_content}" | jq ".name")
            type=$(echo "${idx_content}" | jq ".type")
            content=$(echo "${idx_content}" | jq ".content")
            proxied=$(echo "${idx_content}" | jq ".proxied")
            ttl=$(echo "${idx_content}" | jq ".ttl")
            echo "${name}[${type}] = '${content}' (${ttl},${proxied})"
        done

        exit 0
    fi

    # delete
    if [[ "${CHANGED_IP}" = "del" ]] || [[ "$RECORD_TYPE" = "del" ]]; then
        echo "domain value delete"
        curl -sk --request DELETE \
            --url "$V4/$ZN/dns_records/${AIDARY}" \
            -H "$H1" -H "$H2" \
            | grep -Po '(?<="name":")[^"]*|(?<="content":")[^"]*|(?<=Z"},)[^}]*|(?<="success":false,)[^$]*|(?<=\s\s)[^$]*' | xargs
        exit 0
    fi

    # update
    echo "domain is already exist, update it (overwrite)"
    curl -sk --request PUT \
        --url "$V4/$ZN/dns_records/${AIDARY}" \
        -H "$H1" -H "$H2" \
        --data "{\"type\":\"${RECORD_TYPE}\",\"name\":\"${RECORD}\",\"content\":\"${CHANGED_IP}\",\"proxied\":$Proxied,\"ttl\":$TTL}" \
        | grep -Po '(?<="name":")[^"]*|(?<="content":")[^"]*|(?<=Z"},)[^}]*|(?<="success":false,)[^$]*|(?<=\s\s)[^$]*' | xargs

    exit 0
fi


echo "domain is not exist, create it"
curl -sk --request POST \
    --url "$V4/$ZN/dns_records" \
    -H "$H1" -H "$H2" \
    --data "{\"type\":\"${RECORD_TYPE}\",\"name\":\"${RECORD}\",\"content\":\"${CHANGED_IP}\",\"proxied\":$Proxied,\"ttl\":$TTL}" \
    | grep -Po '(?<="name":")[^"]*|(?<="content":")[^"]*|(?<=Z"},)[^}]*|(?<="success":false,)[^$]*|(?<=\s\s)[^$]*' | xargs









