#!/usr/bin/perl -w

use LWP;
use strict;

#my $pmid = $ARGV[0];
my $url = "http://chem2.sis.nlm.nih.gov/chemidplus/ProxyServlet?objectHandle=DBMaint&actionHandle=default&nextPage=jsp/chemidlite/ResultScreen.jsp&TXTSUPERLISTID=015722482";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or print "Error: " . $response->code . " " . $response->message;
print $response->content;