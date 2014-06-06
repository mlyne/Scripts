#!/usr/bin/perl -w

use LWP;
use strict;

#my $pmid = $ARGV[0];
my $url = "https://www2.delphion.com/cgi-bin/ncommerce3/ExecMacro/IPN/IPNqrysave.d2w/input?query=(DHFR AND arthritis)&-c=deappsft deft epaft epbft inpadoc japan patentft pctft usappsft&-i=VDKVGWKEY PD TITLE SCORE&-o=SCORE&mode=add&form=patsearch";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or print "Error: " . $response->code . " " . $response->message;
print $response->content;