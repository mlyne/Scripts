#!/usr/bin/perl -w

use LWP;
use strict;

my $drug_file = $ARGV[0];
my $out_file = $ARGV[1];

open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open (OFILE, "> $out_file") || die "cannot open $out_file: $!\n";

READ_DRUG_LOOP:while (<DFILE>)
{
chomp; # remove newlines

# Assign drug query
my $drugExp = $_;


my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
"&db=pubmed&term=$drugExp&doptcmdl=MEDLINE&dispmax=1";
my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
#$response->is_success or "failed";
$response->is_success or print "$drugExp - Error: " . $response->code . " " . $response->message, "\n";
print OFILE $response->content;

}

close DFILE;
close OFILE;