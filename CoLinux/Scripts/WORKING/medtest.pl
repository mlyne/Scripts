#!/usr/bin/perl -w

use LWP;
use strict;

my $drug = $ARGV[0];
my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
"&db=pubmed&term=$drug+AND+inflammation&doptcmdl=docsum&dispmax=20";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;