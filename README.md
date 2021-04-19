# STIR/SHAKEN Test Suite

## About

This project implements a test suite to verify the correctness and robustness of STIR/SHAKEN
verification and authorization service implementations in line with the following RFCs:

* RFC 8224 - Authenticated Identity Management in the Session Initiation Protocol (SIP)
* RFC 8225 - PASSporT: Personal Assertion Token
* RFC 8226 - Secure Telephone Identity Credentials: Certificates
* RFC 8588 - Personal Assertion Token (PaSSporT) Extension for Signature-based Handling of Asserted information using toKENs (SHAKEN)

## WARNING

This version still has `sipp.opensipit.sipfront.org` as x5u URL scattered all around the code and
scenarios and will be made configurable in the future.

For now, run a quick hacky search/replace over it, like so:

```
perl -pi -e 's/sipp.opensipit.sipfront.org\/cert.pem/url.of.your\/cert.pem/' *
perl -pi -e 's/sipp.opensipit.sipfront.org\/cert.pem/url.of.your\/cert.pem/' helpers/*
perl -pi -e 's/sipp.opensipit.sipfront.org\/cert.pem/url.of.your\/cert.pem/' scenarios/*
```

Also, due to a (for now) hardcoded path in SIPp, this repo must be cloned into your
local path `/home/admin/stirshaken-scenarios`, otherwise it will NOT work.

```
mkdir -p /home/admin/
cd /home/admin
git clone https://github.com/agranig/stirshaken-scenarios.git
```

## Prerequisites

On Debian buster, install the dependencies as follows.

```
# libks and libstirshaken1 are from the freeswitch repo
apt-get update
apt-get install -y gnupg2 wget lsb-release
wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/freeswitch.list
deb http://files.freeswitch.org/repo/deb/debian-release/ buster main
deb-src http://files.freeswitch.org/repo/deb/debian-release/ buster main
EOF

apt-get update
apt-get install -y libks libstirshaken1 libuuid1 \
    libcrypt-jwt-perl libdata-uuid-perl libcryptx-perl \
    libfaketime
```

## Serving the certificates

You can either bring your own certificates, or generate a test CA and the corresponding certs within
the test suite.

### Using your own certificates

Copy your certificates and private keys into `certs/sp`, so the test suite can find them and use them to
sign the messages.

Note that the file names in certs/sp/ must match the names below!

```
# the valid certificate
cp /path/to/cert.pm certs/sp/cert.pem

# again the valid certificate, but we'll serve this on
# a different port, and to avoid caching on the client
# side, we use a different name
cp /path/to/cert.pm certs/sp/copyofcert.pem

# the private key belonging to your valid certificate
cp /path/to/priv.key certs/sp/priv.pem

# the ca certificate for your valid certificate
cp /path/to/cacert.pem certs/ca/cacert.pem

# an expired certificate with the same key as above
cp /path/to/expired.pem certs/sp/expired.pem

# a certificate valid only in the future, with same key as above
cp /path/to/future.pem certs/sp/future.pem

# a certificate signed by an untrusted CA
cp /path/to/untrusted.pm certs/sp/untrusted.pem

# and the corresponding priv key for the untrusted cert
cp /path/to/untrusted.key certs/sp/untrusted.key

### here go some auto-generated fake certificates we'll need

# an empty certificate
> certs/sp/empty.pem

# a certificate full of garbage
> certs/sp/garbage.pem
for i in $(seq 0 4096); do echo -n a >> certs/sp/garbage.pem; done
```

### Generating fresh CA and SP certificates

Don't copy/paste this, as it will require user input on create-ca.sh. Rather, put
it in a file and execute it (we'll create a helper script around that in the future).

```
# set up a new CA
./helpers/create-ca.sh

# create a valid certificate
./helpers/create-cert.sh 365
cp certs/ca/temp/cert.pem certs/ca/temp/priv.pem certs/sp/

# again the valid certificate, but we'll serve this on
# a different port, and to avoid caching on the client
# side, we use a different name
cp certs/sp/cert.pm certs/sp/copyofcert.pem

# an expired certificate with the same key as above
./helpers/create-cert.sh 365 -3650 1
cp certs/ca/temp/cert.pem certs/sp/expired.pem

# a certificate valid only in the future, with same key as above
./helpers/create-cert.sh 365 +3650 1
cp certs/ca/temp/cert.pem certs/sp/future.pem

# create a new untrusted CA and cert
mkdir certs/ca/cabak && mv certs/ca/*.pem certs/ca/cabak
./helpers/create-ca.sh
./helpers/create-cert.sh 365
cp certs/ca/temp/cert.pem certs/sp/untrusted.pem
cp certs/ca/temp/priv.pem certs/sp/untrusted.key
mv certs/ca/cacert.pem certs/ca/untrusted-cacert.pem
mv certs/ca/cakey.pem certs/ca/untrusted-cakey.pem
mv certs/ca/cacert.srl certs/ca/untrusted-cacert.srl
mv certs/ca/cabak/*.pem certs/ca
rm -rf certs/ca/cabak

### here go some auto-generated fake certificates we'll need

# an empty certificate
> certs/sp/empty.pem

# a certificate full of garbage
> certs/sp/garbage.pem
for i in $(seq 0 4096); do echo -n a >> certs/sp/garbage.pem; done
```

The certificates referenced in the x5u of the PASSporT and the info param of the Identity
header must be provided via http also. There is a helper script `helpers/run-httpserver.sh`
using Python's built-in http server, which you can use to serve certs on both port 80 and 8080,
which are used throughout the tests:

```
# in one terminal
helpers/run-httpserver.sh 80

# in another terminal
helpers/run-httpserver.sh 8080
```

## Usage

You have to set up your environment per test target, then you can run each test automatically.
If one test hangs, just CTRL+C and investigate the error and message log for the test number in
`runs/$TARGET`.

```
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

for test in *.sh; do ./$test "$TARGET"; sleep 1; done
```

## SIPp version

This testsuite currently uses a binary version of SIPp in helpers/sipp including
STIR/SHAKEN support. You have to install libstirshaken to be able to run it.

We'll provide a patch against upstream SIPp (and will try to get it merged into
upstream) as soon as possible.
