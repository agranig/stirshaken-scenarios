#!/bin/sh

BD="$(dirname $0)"
S="$BD/scenarios/401-attest-empty.xml"

T=$1
if [ -z "$T" ]; then
    echo "Usage: $0 <target-uri>"
    exit 1
fi
SIPP="$BD/helpers/sipp"
RUNNER="$BD/helpers/run-invite.sh"

"$RUNNER" "$SIPP" "$S" "$T" "$BD/helpers/create-jwt.pl --keypath=$BD/certs/sp/priv.pem --autoiat --autoorigid --origtn=439991001 --desttn=439991002 --x5u=http://sipp.opensipit.sipfront.org/cert.pem --attest=SF_EMPTY"
