#!/usr/bin/perl -w
 
use LWP;
use strict;
 
my $pmid = $ARGV[0];     # we’ve used a Perl trick here to pass
                      # some information (the id code) to the program
my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?term=aspirin+AND+pain";  # Again, this should be all one line!
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "Ooops! failed...";
print $response->content;
 
