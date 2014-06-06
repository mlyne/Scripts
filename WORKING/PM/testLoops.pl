#!/usr/bin/perl -w

use LWP;
use DateTime;
use strict;

my $usage = "Usage:citemap_pm.pl (TermFile1 TermFile2) TermFile3  out_file > err.txt

Contents of F1 & F2 are concatenated --> matrix rows
F3 --> matrix headers
\n";

unless ( $ARGV[3] ) { die $usage }

# Take input from the command line
my $indic_file = $ARGV[0];
my $scope_file = $ARGV[1];
my $country_file = $ARGV[2];
my $out_file = $ARGV[3];

my $dispmax = 1;

# Open Drug and Query files
open(IFILE, "< $indic_file") || die "cannot open $indic_file: $!\n";
open(SFILE, "< $scope_file") || die "cannot open $scope_file: $!\n";
open(QFILE, "< $country_file") || die "cannot open $country_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

# Read scope into an array
chomp (my @scope = <SFILE>); 

# Read queries into an array
chomp (my @country = <QFILE>); 

# Get local time and write to file
my $stamp = DateTime->now( time_zone => 'Europe/London' );
print OUT_FILE "# ", $stamp->dmy, "\t", $stamp->hms, "\n";

### Header for column 1
print OUT_FILE "Name\tRowSearch";

# Loop over Query file with counter to plot header co-ordinates
for my $country_header (@country)
{	
	my ($country_h, $countrExpr) = split /\t/, $country_header;
	print OUT_FILE "\t", $country_h;
	
}
# End of line for text file country headers
print OUT_FILE "\n";

# Search terms header line
print OUT_FILE "ColSearch\tSearch";

for my $country_term (@country)
{	
	my ($coutryID, $countryExpr) = split /\t/, $country_term;
	print OUT_FILE "\t", $countryExpr;	
}

# End of line for text file search terms
print OUT_FILE "\n";

# Loops through Indic file
READ_INDIC_LOOP:while (<IFILE>)
{
	chomp; # remove newlines
	
	# Assign Indic query
	my ($indID, $indicExp) = split /\t/, $_;
	
	my $indicName = $indID;
	print $indicName, "\n";
	
 	READ_SCOPE_LOOP:for my $scopeLine (@scope)
 	{
 		#chomp; # remove newlines

 		my ($scopeID, $scopeExp) = split /\t/, $scopeLine;
 		#print "POOP ", $scopeID, "\n";
 		my $termID = join "_", $indicName, $scopeID;
 		my $filler = " AND ";
 		my $combExp = $indicExp . $filler . $scopeExp;
 		print "TERM: ", $termID, "\n";
 		print "EXPR: ", $combExp, "\n";
	
# Write Indic names to text file
		print OUT_FILE $termID, "\t", $combExp;

# Write our Indic names in the first column of the spreadsheet
# Start at row #2 as row #1 has country headers
	
	# Loops over array of Countries
	READ_COUNTRY_LOOP: for my $terr (@country)
	{
	  my ($countryID, $countryExp) = split /\t/, $terr;
#	  my $finalExpr = "stuff__" . $combExp . "+AND+" . $countryExp, "+2008:2012[dp]+NOT+review[pt]" . 
#	  "&tool=eSearchTool" .
#	  "&email=mlyne\.careers\@gmail.com";
#	  print "EXPR: ", $finalExpr, "\n";

# Write search params to Log file
 		my $tp = DateTime->now( time_zone => 'Europe/London' );
 		print $tp->hms, " (UK) : ", $countryExp, "\n";        
 		
# Make use of LWP to make call to PubMed query website

         my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=pubmed&rettype=count&term=" . $combExp  . # test URL 2
         "+AND+" . $countryExp . "+2008:2012[dp]+NOT+review[pt]" .
         "&tool=eSearchTool" .
         "&email=mlyne\.careers\@gmail.com";
                
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$combExp: $countryExp\tError: " . 
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
#		print OUT_FILE "\t", "RESULT";

	}# End COUNTRY_LOOP
	print "\n";

# Write end of line to text file
	print OUT_FILE "\n";
	
	}# End SCOPE_LOOP
	
}# End INDIC_LOOP


# Close the file we've opened
close(IFILE);
close(SFILE);
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

