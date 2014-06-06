#!/usr/bin/perl -w

use LWP;
use strict;

while (<>) {
	chomp;
	my $query = ($_);
	my ($results) = query($query);
	print "$$results\n";
	
}
	
sub query {

        my $query = shift;
        my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=mesh&cmd=search&term=$query&dopt=ASN1";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$query\tError: " . 
        $response->code . " " . $response->message, "\n";
        my ($result) = $response->content;
        return \$result;
        
}