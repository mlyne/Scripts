#!/usr/bin/perl -w

use LWP;
use strict;

while (<>) {
	chomp;
	my $query = ($_);
	my ($results) = query($query);
	print "<H1>*** $query ***<H1>\n";
	print "$$results\n";
	print "EOF\n";
	
}
	
sub query {

        my $query = shift;
        my $url = "http://www.nlm.nih.gov/cgi/mesh/2004/MB_cgi?term=$query";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or die "failed";
        my ($result) = $response->content;
        return \$result;
        
}