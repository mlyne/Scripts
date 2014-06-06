#!/usr/bin/perl -w

use LWP;
use strict;

my $drug = $ARGV[0] ? $ARGV[0] : "morphine[tiab]";
my $query = $ARGV[1] ? $ARGV[1] : "pain[tiab]";
my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?db=pubmed&term=$drug+$query";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or die "failed";

my @out = split(/<DbName>/, $response->content);
my %results;

my ($entry) = grep /PubMed/, @out;
my ($hitCount) = ($entry =~ m/\<Count\>(\d+)\</);

print $drug, "\t", $query, "\n";
print "PubMed\t", $hitCount, "\n" if $hitCount;

