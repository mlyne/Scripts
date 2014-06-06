#!/usr/bin/perl -w

use LWP;
use strict;

my $omid = $ARGV[0];
my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Text" .
"&db=OMIM&uid=$omid&dopt=Detailed";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;