#!/usr/bin/perl -w

use LWP;
use strict;
my $num = $ARGV[1];
my $limit = "2" unless $num;


while (<>) {
	chomp;
	my $query = ($_);
	my ($results) = query($query);
	print "$$results\n";
	
}
	
sub query {

        my $query = shift;
        my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=MeSH&term=$query&dopt=MEDLINE&dispmax=$limit";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or die "failed";
        my ($result) = $response->content;
        return \$result;
        
}