#!/usr/bin/perl -w

use LWP;
use strict;

my $count;

while (<>) {
	chomp;
	my $query = ($_);
	my ($results) = query($query);
	$count++;
	print "$$results\n";
	
	print $count, "\n";
	if ($count > 98) {
#		print "sleepy\n";
		$count = 1;
		sleep 1200;
	}
	
}
	
sub query {

        my $query = shift;
        my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?&db=mesh&doptcmdl=docsum&dispmax=1&term=$query";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$query\tError: " . 
        $response->code . " " . $response->message, "\n";
        my ($result) = $response->content;
        sleep 3;
        return \$result;
        
        
}