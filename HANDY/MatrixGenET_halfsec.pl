#!/usr/bin/perl -w

use LWP;
use DateTime;
use strict;

# Take input from the command line
my $drug_file = $ARGV[0];
my $query_file = $ARGV[1];
my $out_file = $ARGV[2];

my $usage = "Usage:MatrixGenET_halfsec.pl drg_file query_file out_file > err_file.txt\n
";

unless ( $ARGV[2] ) { die $usage }

my $dispmax = 1;

# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

# Read queries into an array
chomp (my @query = <QFILE>); 

# Get local time and write to file
my $stamp = DateTime->now( time_zone => 'Europe/London' );
print OUT_FILE "# ", $stamp->dmy, "\t", $stamp->hms, "\n";

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
Time_Check(); ### take out for testing
	
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
		my $tp = DateTime->now( time_zone => 'Europe/London' );
		print $tp->hms, " (UK) : ", $entry, "\n";        
		
# Make use of LWP to make call to PubMed query website

        my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=pubmed&rettype=count&term=$drugExp" . # test URL 2
        "+AND+$entry+NOT+review[pt]" .
        "&tool=eSearchTool" .
        "&email=mlyne\.careers\@gmail.com";
                
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$drugName, $entry\tError: " . 
        $response->code . " " . $response->message, "\n";
        select(undef, undef, undef, 0.1); # PubMed requires that we have no more than 3 requests / second so delay half second
        
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
                        sleep 60;
                        
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


