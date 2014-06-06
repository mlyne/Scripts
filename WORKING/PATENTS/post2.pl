#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw/POST/;

 
# Parameters for the request
my $query = 'pa=arakis'; # query in CQL
my $range = '50-60'; # define output range
#my $end= '50'; # end of output range
 
# Create a user agent
my $ua = LWP::UserAgent->new();
 
# URL for service (endpoint)
my $url = 'http://ops.epo.org/3.0/rest-services/published-data/search';
 
# Populate POST data fields (key => value pairs)
my (%post_data) = (
		   'q' => $query,
		    #'range' => $range
#		   'start' => $start,
#		   'end' => $end,
#		   'style' => $style
		   );
 
# Perform the request
my $response = $ua->POST( $url, \%post_data );
#my $response = $ua->post( $url, \%post_data );

#$req->content_type('application/x-www-form-urlencoded');
#$req->content("cmd=search&term=$search_term&DB=$dbname&CrntRpt=Abstract");
 
# Check for HTTP error codes
die 'http status: ' . $response->code . ' ' . $response->message unless ($response->is_success); 
 
# Output the entry
print $response->content();

