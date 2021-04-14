#!/bin/sh

BD="$(dirname $0)"
S="$BD/scenarios/300-orig-dest-tn-missing.xml"

T=$1
if [ -z "$T" ]; then
    echo "Usage: $0 <target-uri>"
    exit 1
fi
SIPP="$BD/helpers/sipp"
RUNNER="$BD/helpers/run-invite.sh"

"$RUNNER" "$SIPP" "$S" "$T" "$BD/helpers/create-jwt.pl --keypath=$BD/certs/sp/priv.pem --autoiat --autoorigid --x5u=http://sipp.opensipit.sipfront.org/cert.pem --attest=B"
