#!/usr/bin/perl -w
# Takes a file of "pubmed query list" eg. drug names
# It then queries pubmed and returns a list of the
# number of hits in PubMed

use LWP;
use Time::Object;
use strict;

my $drug_file = $ARGV[0];
my $out_file = $ARGV[1];

open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open (OFILE, "> $out_file") || die "cannot open $out_file: $!\n";
my $queryCount = 1;

READ_DRUG_LOOP:while (<DFILE>)
{
chomp; # remove newlines

# Assign drug query
my $drugExp = $_;

# Check the time ###
	$queryCount++;
			
	if ($queryCount == 99)
	{
		sleep 300;
		$queryCount = 1;
	}
	

my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=pubmed&rettype=count&term=$drugExp" . 
"&tool=PMhitCount" .
"&email=mlyne\@sosei.com";

my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or print "$drugExp - Error: " . 
$response->code . " " . $response->message, "\n";
sleep 3;

# Write search params to Log file
my $tp = localtime;
print $tp->hms, " ", $drugExp, "\n";    

my $res; # Declare var for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

$res = $response->content;
my $valid = "true" if ($res =~ m/eSearchResult/);

# Then use grep to retrieve the line with reference info
# feed into $entry

my ($hitCount) = defined $valid ? ($res =~ m/\<Count\>(\d+)\</) : ("12321");


# Write Co-oc frequencies to Text file
print OFILE $drugExp, "\t", $hitCount, "\n";

}

close DFILE;
close OFILE;

