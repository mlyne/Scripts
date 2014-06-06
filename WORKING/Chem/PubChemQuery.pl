#!/usr/bin/perl -w

use LWP;
use strict;

my $queryCount = 1;

while (<>) {
	
	chomp;
	my $query = ($_);
	my ($results) = query($query);
	print "<TR><TH align=left>MyQuery</TH><TD>$query</TD></TR>\n";
	print "$$results\n";
	print "EOF\n";
	
	$queryCount++;
			
	if ($queryCount == 99)
	{
		sleep 300;
		$queryCount = 1;
	}
}
	
sub query {

        my $query = shift;
#        my $url = "http://www.ncbi.nlm.nih.gov/sites/entrez?db=pccompound&dispmax=1&term=$query";
        my $url = "http://www.ncbi.nlm.nih.gov/sites/entrez?db=pcsubstance&dispmax=1&term=$query";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or die "failed";
        my ($result) = $response->content;
        return \$result;
        
}