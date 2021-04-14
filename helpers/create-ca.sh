#!/bin/bash -e

# This script is based on the work of Liviu Chricu <liviu@opensips.org>

BD=$(dirname "$0")

CA_DIR="$BD/../certs/ca"
if [ -e "$CA_DIR/cacert.pem" ]; then
    echo "There already is a CA certificate $CA_DIR/cacert.pem, clear the directory $CA_DIR and try again!"
    exit 1
fi

pushd "$BD/../certs/ca"

openssl ecparam -noout -name prime256v1 -genkey -out cakey.pem
openssl req -x509 -new -nodes -key cakey.pem -sha256 -days 1825 -out cacert.pem

popd
