#!/usr/bin/perl -w

use LWP;
use Time::Object;
use strict;

# Take input from the command line
my $drug_file = $ARGV[0];
my $query_file = $ARGV[1];
my $out_file = $ARGV[2];

my $dispmax = 1;

# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

# Read queries into an array
chomp (my @query = <QFILE>); 

# Get local time and write to file
my $stamp = localtime;
print OUT_FILE "# ", $stamp->cdate, "\n";

### Header for column 1
print OUT_FILE "Name\tRowSearch";

# Loop over Query file with counter to plot header co-ordinates
for my $query_header (@query)
{	
	# Shortcircuit "if:then:else" operator
	my ($query_h) = ($query_header =~ m/^\(*(.+?)\[.+$/) ? $1 : $query_header;
	print OUT_FILE "\t", $query_h;
	
}
# End of line for text file query headers
print OUT_FILE "\n";

# Search terms header line
print OUT_FILE "ColSearch\tSearch";

for my $query_term (@query)
{	
	print OUT_FILE "\t", $query_term;	
}

# End of line for text file search terms
print OUT_FILE "\n";

# Loops through Drug file
READ_DRUG_LOOP:while (<DFILE>)
{
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
# Check the time ###
Time_Check();
	
# If it contains a regular expression - get rid of it
	my ($drugName) = ($drugExp =~ m/^\(*(.+?)\[.+$/) ? $1 : $drugExp;
	print $drugName, "\n";
	
# Write drug names to text file
	print OUT_FILE $drugName, "\t", $drugExp;

# Write our Drug names in the first column of the spreadsheet
# Start at row #2 as row #1 has query headers
	
	# Loops over array of Queries
	READ_QUERY_LOOP: for my $entry (@query)
	{
	
# Write search params to Log file
		my $tp = localtime;
		print $tp->hms, " ", $entry, "\n";        
		
# Make use of LWP to make call to PubMed query website

        my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?term=$drugExp" .
        "+AND+$entry+NOT+review[pt]" .
        "&tool=SearchLITE" .
        "&email=michaellyne\@arakis.com";
        
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$drugName, $entry\tError: " . 
        $response->code . " " . $response->message, "\n";
        sleep 3;
        
        my (@res); # Declare array for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

        @res = split(/<DbName>/, $response->content);
        my $valid = "true" if (scalar(@res) > 1);

# Then use grep to retrieve the line with reference info
# feed into $entry

		my ($entry) = grep /PubMed/, @res;
		my ($hitCount) = defined $valid ? ($entry =~ m/\<Count\>(\d+)\</) : ("12321");

# Write Co-oc frequencies to Text file
		print OUT_FILE "\t", $hitCount;

	}# End QUERY_LOOP
	print "\n";

# Write end of line to text file
	print OUT_FILE "\n";
	
}# End DRUG_LOOP

# Close the file we've opened
close(DFILE);
close(QFILE);
close(OUT_FILE);

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
		print $hour, "h - day before so adjusting for day ", $dayNum, "\n";
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

