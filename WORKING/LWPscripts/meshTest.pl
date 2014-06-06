#!/usr/bin/perl -w

use LWP;
use strict;

my $omid = $ARGV[0];
#my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Text" .
#"&db=OMIM&uid=$omid&dopt=Detailed";
my $url = "http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/meshbrowser?cmd=Text&retrievestring=&mbdetail=n&term=Anti-Glomerular+Basement+Membrane+Disease";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;