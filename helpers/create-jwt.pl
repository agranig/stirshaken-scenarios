#!/usr/bin/env perl
use strict;
use warnings;

use Crypt::JWT qw/encode_jwt/;
use Crypt::PK::ECC;
use Getopt::Long;
use Data::UUID;

my $iat;
my $autoiat;
my $attest;
my $origtn;
my $desttn;
my $origid;
my $autoorigid;
my $x5u;
my $keypath;
my $help;
my $headerstr;
my $payloadstr;

my $header = {};
my $payload = {};

$header->{alg} = 'ES256';
$header->{ppt} = 'shaken';
$header->{type} = 'passport';

sub usage {
    print "$0 <args>\n".
    "    --keypath=s  M - Path to ECC private key to sign JWT\n".
    "    --header=s   O - Use string as b64-encoded header part in JWT\n".
    "    --payload=s  O - Use string as b64-encoded payload part in JWT\n".
    "    --x5u=s      O - Put x5u with the given value in header\n".
    "    --iat=s      O - Put iat with the given value in playload\n".
    "    --autoiat    O - Put iat with current time in playload\n".
    "    --origid=s   O - Put origid with the given value in playload\n".
    "    --autoorigid O - Put origid with auto-generated uuid in playload\n".
    "    --attest=s   O - Put attest with the given value in playload\n".
    "    --origtn=s   O - Put orig.tn with the given value in playload\n".
    "    --desttn=s   O - Put dest.tn[] with the given value in playload\n";
}

GetOptions(
    "help" => \$help,
    "keypath=s" => \$keypath,
    "x5u=s" => \$x5u,
    "iat=s" => \$iat,
    "autoiat" => \$autoiat,
    "attest=s" => \$attest,
    "origtn=s" => \$origtn,
    "desttn=s" => \$desttn,
    "origid=s" => \$origid,
    "autoorigid" => \$autoorigid,
    "header=s" => \$headerstr,
    "payload=s" => \$payloadstr,
) or die "Invalid command line arguments\n";

if (defined $help) {
    usage && exit 0;
}

unless (defined $keypath) {
    print STDERR "Missing --keypath argument\n";
    usage and exit 1;
}
unless (-r $keypath) {
    print STDERR "Unreadable --keypath '$keypath'\n";
    exit 1;
}

if (defined $x5u) {
    $header->{x5u} = $x5u;
}

unless (defined $iat) {
    if ($autoiat) {
        $payload->{iat} = time;
    }
} else {
    if ($iat =~ /^\-?\d+$/) {
        $iat = int($iat);
    }
    $payload->{iat} = $iat;
}

unless (defined $origid) {
    if ($autoorigid) {
        $payload->{origid} = lc(Data::UUID->new->create_str());
    }
} else {
    $payload->{origid} = $origid
}

if (defined $attest) {
    if ($attest eq "SF_EMPTY") {
        $attest = "";
    }
    $payload->{attest} = $attest;
}

if (defined $origtn) {
    if ($origtn eq "SF_EMPTY") {
        $origtn = "";
    }
    $payload->{orig}->{tn} = $origtn;
}

if (defined $desttn) {
    if ($desttn eq "SF_EMPTY") {
        $desttn = "";
    }
    $payload->{dest}->{tn} = [ $desttn ];
}

if (defined $payloadstr) {
    $payload = $payloadstr;
}


my $jwt = encode_jwt(
    key => Crypt::PK::ECC->new($keypath),
    alg => 'ES256',
    auto_iat => 0,
    extra_headers => $header,
    payload => $payload,
);

print $jwt;
