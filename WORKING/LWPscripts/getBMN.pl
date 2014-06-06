#!/usr/bin/perl -w

use LWP;
use strict;

#my $pmid = $ARGV[0];
my $url = "http://journals.bmn.com/medline/search/record?uid=MDLN.20066851&rendertype=full";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";
print $response->content;