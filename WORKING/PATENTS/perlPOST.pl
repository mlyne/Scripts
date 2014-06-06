#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw/POST/;

my(@fields) = (
    'http://ops.epo.org/3.0/rest-services/published-data/search',
    [ q => 'pa=arakis' ]
#      begin => '50',
#      end => '60' ]
      
#     [ data1 => 'something',
#       data2 => 'somethingelse',
#       syntax => 'SQL' ]
);

my $ua = LWP::UserAgent->new;

my $req = POST @fields;
print $ua->request($req)->as_string();

###
# Load LWP
# use LWP::UserAgent;
#  
# # Parameters for the request
# my $db = 'uniprotkb'; # Database: UniProtKB
# my $id = 'WAP_RAT,WAP_MOUSE'; # Entry identifiers
# my $format = 'uniprot'; # Result format
# my $style = 'raw'; # Result style
#  
# # Create a user agent
# my $ua = LWP::UserAgent->new();
#  
# # URL for service (endpoint)
# my $url = 'http://www.ebi.ac.uk/Tools/dbfetch/dbfetch';
#  
# # Populate POST data fields (key => value pairs)
# my (%post_data) = (
# 		   'db' => $db,
# 		   'id' => $id,
# 		   'format' => $format,
# 		   'style' => $style
# 		   );
#  
# # Perform the request
# my $response = $ua->post($url, \%post_data);
#  
# # Check for HTTP error codes
# die 'http status: ' . $response->code . ' ' . $response->message unless ($response->is_success); 
#  
# # Output the entry
# print $response->content();

# # build the request
#$args = "CMD=Put&PROGRAM=$program&DATABASE=$database&QUERY=" . $encoded_query;

#$req = new HTTP::Request POST => 'http://www.ncbi.nlm.nih.gov/blast/Blast.cgi';
#$req->content_type('application/x-www-form-urlencoded');
#$req->content($args);


