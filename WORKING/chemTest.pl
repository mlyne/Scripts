#!/usr/bin/perl -w

use LWP;
use strict;

my $drug = $ARGV[0];

my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=pccompound&term=$drug&doptcmdl=docsum&dispmax=1";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;