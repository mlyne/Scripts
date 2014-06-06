#!/usr/bin/perl -w

use LWP;
use strict;

my $drug = $ARGV[0];

my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?" .
"&db=pubmed&rettype=count&term=$drug+AND+inflammation";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;