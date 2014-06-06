#!/usr/bin/perl -w

use LWP;
use strict;

my $drug = $ARGV[0];
my $query = $ARGV[1];
print "$drug $query\n";

my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
"&db=pubmed&term=$drug+AND+$query&doptcmdl=docsum&dispmax=2";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";

my @res = split("\n", $response->content);
my ($line) = grep />No items /, @res;

print $line, "\n" if ($line);
# print $response->content;


my $val = "0";

if ($line) 
{
	($val) = ($line =~ m/\>Item 1 of (\d+)\</);
}

#print $val;

# print $response->content;