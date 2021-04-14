#!/bin/bash -e

# This script is based on the work of Liviu Chircu <liviu@opensips.org>

function usage () {
    echo "Usage: $0 <days-valid> [days-shift]"
    echo "  days-valid: How many days the cert is valid from start date"
    echo "  days-shift: How many days to shift the start date back (eg -365) or forth (eg +365) from today"
    echo ""
    echo "Example: $0 365"
    echo "   Certificate is valid from today for 365 days"
    echo "Example: $0 365 -3650"
    echo "   Certificate was valid from 10 years ago today for 365 days"
}

VALID_DAYS=$1
START_AT=$2

if [ -z "$VALID_DAYS" ]; then
    usage
    exit 1
fi

BD=$(dirname "$0")

CA_DIR="$BD/../certs/ca"
TMP_DIR="$CA_DIR/temp"

rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"

pushd "$TMP_DIR"

cat >TNAuthList.conf << EOF
asn1=SEQUENCE:tn_auth_list
[tn_auth_list]
field1=EXP:0,IA5:1001
EOF

openssl asn1parse -genconf TNAuthList.conf -out TNAuthList.der
cat >openssl.conf << EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[ req_distinguished_name ]
commonName = "SHAKEN"
[ v3_req ]
EOF

od -An -t x1 -w TNAuthList.der | sed -e 's/ /:/g' -e 's/^/1.3.6.1.5.5.7.1.26=DER/' >>openssl.conf

openssl ecparam -noout -name prime256v1 -genkey -out priv.pem
openssl req -new -nodes -key priv.pem -keyform PEM \
  -subj '/C=US/ST=VA/L=Somewhere/O=AcmeTelecom, Inc./OU=VOIP/CN=SHAKEN' \
  -sha256 -config openssl.conf \
  -out csr.pem

FT=""
if [ "$START_AT" != "" ]; then
    START_AT="${START_AT}d"
    FT_LIB="$(dpkg -L libfaketime | grep libfaketime.so.1)"
    if [ "$FT_LIB" = "" ]; then
        echo "Failed to find libfaketime.so.1, maybe libfaketime is not installed?"
        exit 1
    fi
    FT="env LD_PRELOAD=$FT_LIB FAKETIME=$START_AT"
fi

$FT openssl x509 -req -in csr.pem -CA ../cacert.pem -CAkey ../cakey.pem -CAcreateserial \
-days $VALID_DAYS -sha256 -extfile openssl.conf -extensions v3_req -out cert.pem

rm csr.pem

popd
