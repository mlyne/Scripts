#!/usr/bin/perl -w
 
use LWP;
use strict;
 

 
my $file = $ARGV[0];
open(FILEO, "< $file") || die "cannot open $file: $!\n";
READ_LOOP:while (<FILEO>)
{
chomp(my $pmid = ($_) );
#print $pmid, "\n";
                     
my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=PubMed&uid=$pmid&dopt=abstract";  
      
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;

}
 
