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
my $stamp = DateTime->now( time_zone => 'Europe/London' );
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
		my $tp = DateTime->now( time_zone => 'Europe/London' );
		print $tp->hms, " (UK) : ", $drugName, "\n";        
		
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
        
        my $early = "2100";
	my $late = "0500";
        #my $late = "0220"; 

	my$locTime = localtime();
	print "Local Time: ", $locTime, "\n";
        
        my $t = DateTime->now( time_zone => 'America/New_York' ); # Change zone to Eastern Time
        print $t->hms, " : Eastern Time\n";

        my @ltime = split(/:/, $t->hms);
        my $hour = $ltime[0];
	#$hour +=4; # Fiddle factor to get over the midnight bridge
	my $min = $ltime[1];
	my $time = "$hour$min";
        #my $time = "$ltime[0]$ltime[1]";
	#print "time ", $time, "\n";
        #print "hour ", $hour, "\n";

        my $dayNum = $t->wday; # 1-7 (Monday is 1) - 
        print "day ", $dayNum, " (Monday is 1)\n";

        #unless (($dayNum < 2) || ($dayNum > 5)) {
	unless ( $dayNum > 5 ) {

                while ($time <= $early && $time >= $late) {
                        print $t->hms, " Eastern Time: time to sleep ($time)\n";
                        sleep 10;
                        
                        $t = DateTime->now( time_zone => 'America/New_York' );
        		@ltime = split(/:/, $t->hms);
        		$hour = $ltime[0];
			#$hour +=4; # Fiddle factor to get over the midnight bridge
			$min = $ltime[1];
			$time = "$hour$min";
                        
                }
	#$dayNum = $t->wday; # 1-7 (Monday is 1)
        }
                
}
