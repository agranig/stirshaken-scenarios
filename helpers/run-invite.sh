#!/bin/bash


usage () {
    echo "Usage: $0 </path/to/sipp> <scenario.xml> <target> [stirshaken-jwt] [identity-mod]"
}

SIPP=$1
if [ -z "$SIPP" ]; then
    usage
    exit 1
fi
if [[ "$SIPP" = ./* ]]; then
    SIPP="$PWD/$SIPP"
fi
if ! [ -x "$SIPP" ]; then
    echo "Invalid sipp path '$SIPP', does not exist or not executable"
    exit 1
fi


S=$2
if [ -z "$S" ]; then
    usage
    exit 1
fi
if ! [ -e "$S" ]; then
    echo "Scenario '$S' does not exist"
    exit 1
fi

T=$3
if [ -z "$T" ]; then
    usage
    exit 1
fi

KEYS=""
PASSPORT=""
JWT=$4
if ! [ -z "$JWT" ]; then
    PASSPORT=$($JWT)
    KEYS="-key custom_identity Identity:$PASSPORT;info=<http://sipp.opensipit.sipfront.org/cert.pem>;alg=ES256;ppt=shaken"
fi

MOD=$5
if [ "$MOD" = "noinfo" ]; then
    KEYS="-key custom_identity Identity:$PASSPORT;alg=ES256;ppt=shaken"
elif [ "$MOD" = "noalg" ]; then
    KEYS="-key custom_identity Identity:$PASSPORT;info=<http://sipp.opensipit.sipfront.org/cert.pem>;ppt=shaken"
elif [ "$MOD" = "wrongalg" ]; then
    KEYS="-key custom_identity Identity:$PASSPORT;info=<http://sipp.opensipit.sipfront.org/cert.pem>;alg=HS256;ppt=shaken"
elif [ "$MOD" = "noppt" ]; then
    KEYS="-key custom_identity Identity:$PASSPORT;info=<http://sipp.opensipit.sipfront.org/cert.pem>;alg=ES256"
elif [ "$MOD" = "wrongppt" ]; then
    KEYS="-key custom_identity Identity:$PASSPORT;info=<http://sipp.opensipit.sipfront.org/cert.pem>;alg=ES256;ppt=foobar"
fi

BD="$(dirname $0)"
BASE="$BD/../runs/$T"
if ! [ -d "$BASE" ]; then
    echo "Base $BASE does not exist, please create it first and copy caller/callee.csv there"
    exit 1
fi

WD=$BASE
if [[ "$BASE" = ./* ]]; then
    WD="$PWD/$BASE"
    S="$PWD/$S"
fi

pushd $BASE
$SIPP -nd -aa -base_cseq 1 -fd 1 -p 5060 \
    -r 1 -m 1 \
    -trace_err -trace_msg \
    -key target_uri "$URI" $KEYS \
    -key current_date "$(env LC_ALL=C TZ=GMT date '+%a, %e %b %Y %T %Z')" \
    -sf "$S" \
    -inf "$WD/caller.csv" \
    -inf "$WD/callee.csv" \
    "$T"
popd
