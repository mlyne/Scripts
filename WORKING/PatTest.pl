#!/usr/bin/perl -w

use LWP;
use strict;

my $drug = $ARGV[0];

my $url = "http://www.freepatentsonline.com/search.pl?p=1&srch=xprtsrch&sf=1&query=" .
"$drug+AND+dipeptidyl&uspat=on&usapp=on&eu=on&date_range=all&stemming=on&sort=chron";

#my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
#"&db=pubmed&term=$drug+AND+inflammation&doptcmdl=docsum&dispmax=20";

my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;