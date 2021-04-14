#!/bin/sh

BD="$(dirname $0)"
S="$BD/scenarios/204-cert-by-untrusted-ca.xml"

T=$1
if [ -z "$T" ]; then
    echo "Usage: $0 <target-uri>"
    exit 1
fi
SIPP="$BD/helpers/sipp"
RUNNER="$BD/helpers/run-invite.sh"

"$RUNNER" "$SIPP" "$S" "$T"
