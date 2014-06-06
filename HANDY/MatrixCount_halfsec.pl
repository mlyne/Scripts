#!/usr/bin/perl -w

use LWP;
use DateTime;
use strict;

# Take input from the command line
my $drug_file = $ARGV[0];
my $out_file = $ARGV[1];

my $dispmax = 1;

# Open Drug
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

# Get local time and write to file
my $stamp = DateTime->now;
print OUT_FILE "# ", $stamp->dmy, "\t", $stamp->hms, "\n";

# Loops through Drug file
READ_DRUG_LOOP:while (<DFILE>)
{
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
# Check the time ###
Time_Check(); ### take out for testing
	
# If it contains a regular expression - get rid of it
	my ($drugName) = ($drugExp =~ m/^\(*(.+?)\[.+$/) ? $1 : $drugExp;
	print $drugName, "\n";
	
# Write drug names to text file
	print OUT_FILE $drugName, "\t", $drugExp;

# Write our Drug names in the first column of the spreadsheet
	
# Write search params to Log file
		my $tp = DateTime->now;
		print $tp->hms, " ", $drugName, "\n";        
		
# Make use of LWP to make call to PubMed query website

        my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=pubmed&rettype=count&term=$drugExp" . # test URL 2
        "&tool=eSearchTool" .
        "&email=mlyne\.careers\@gmail.com";
                
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$drugName, \tError: " . 
        $response->code . " " . $response->message, "\n";
        select(undef, undef, undef, 0.5); # PubMed requires that we have no more than 3 requests / second so delay half second
        
        my $res; # Declare array for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

        $res = $response->content;
        #print $response->content, "\n";
        my $valid = "true" if ($res =~ m/eSearchResult/);

# Then use grep to retrieve the line with reference info
# feed into $entry

		my ($hitCount) = defined $valid ? ($res =~ m/\<Count\>(\d+)\</) : ("12321");

# Write Co-oc frequencies to Text file
		print OUT_FILE "\t", $hitCount;

# Write end of line to text file
	print OUT_FILE "\n";
	
}# End DRUG_LOOP

# Close the file we've opened
close(DFILE);
close(OUT_FILE);

### Subroutines ####
###  Time_Check  ###

sub Time_Check {
	
	#my $early = 1555; 
	#my $late = 1640; 
	
	my $early = "0200"; 
	my $late = "1000"; 
	
	my $t = DateTime->now;
	#print $t->hms, "\n";
	my @ltime = split(/:/, $t->hms);
	my $hour = $ltime[0];
	my $time = "$ltime[0]$ltime[1]";
	#print "hour ", $hour, "\n";

	my $dayNum = $t->wday;
	#print "day ", $dayNum, "\n";

	if ($hour < 5) {
		$dayNum -= 1;
		print $hour, "h - day before so adjusting for day ", $dayNum, "\n";
	}

	unless (($dayNum < 2) || ($dayNum > 6)) {

		while ($time <= $early || $time >= $late) {
			print $time, ": time to sleep\n";
			sleep 180;
			
			$t = DateTime->now;
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

