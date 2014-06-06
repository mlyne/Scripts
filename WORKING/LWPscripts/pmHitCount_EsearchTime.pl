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

READ_DRUG_LOOP:while (<DFILE>)
{
chomp; # remove newlines

# Assign drug query
my $drugExp = $_;

# Check the time ###
Time_Check();

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

### Subroutines ####
###  Time_Check  ###

sub Time_Check {
	
	#my $early = 1555; 
	#my $late = 1640; 
	
	my $early = "0200"; 
	my $late = "1000"; 
	
	my $t = localtime;
	#print $t->hms, "\n";
	my @ltime = split(/:/, $t->hms);
	my $hour = $ltime[0];
	my $time = "$ltime[0]$ltime[1]";
	#print "hour ", $hour, "\n";

	my $dayNum = $t->wday;
	#print "day ", $dayNum, "\n";

	if ($hour < 5) {
		$dayNum -= 1;
		print $hour, " so adjusting for day ", $dayNum, "\n";
	}

	unless (($dayNum < 2) || ($dayNum > 6)) {

		while ($time <= $early || $time >= $late) {
			print $time, ": time to sleep\n";
			sleep 180;
			
			$t = localtime;
			@ltime = split(/:/, $t->hms);
			$time = "$ltime[0]$ltime[1]";
			$hour = $ltime[0];
			
		}
		
		$dayNum = $t->wday;
		if ($hour lt 5) {
			$dayNum -= 1;
		#print $dayNum, "\n";
		}
	}
		
}
