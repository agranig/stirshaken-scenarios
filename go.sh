#!/bin/bash -e

# set your target here
TARGET="kamailio.opensipit.sipfront.org"

# set your caller id here
CALLER_ID="439991001"

# set your called id here
CALLED_ID="439991002"

mkdir -p "runs/$TARGET"

cat <<EOF > "runs/$TARGET/caller.csv"
SEQUENTIAL
$CALLER_ID;$TARGET;$CALLER_ID
EOF

cat <<EOF > "runs/$TARGET/callee.csv"
SEQUENTIAL
$CALLED_ID;$TARGET;$CALLED_ID
EOF

for test in *.sh; do
	echo "\n------------------ start $test"
	./$test "$TARGET"
	echo "------------------ $test done\n"
	sleep 1
done
