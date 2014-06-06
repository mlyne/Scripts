#!/usr/bin/perl -w

use LWP;
use strict;

# Take input from the command line
my $drug_file = $ARGV[0];
my $query_file = $ARGV[1];
my $out_file = $ARGV[2];

# Shortcircuit "if:then:else" operator
my $dispmax = 1;

# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

# Read queries into an array
chomp (my @query = <QFILE>); 

### Header for column 1
print OUT_FILE "Name\tRowSearch";

# Loop over Query file with counter to plot header co-ordinates
for my $query_header (@query)
{	
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

	### TIMING SECTION ###
	# Only allowed to query Pubmed between 9pm & 5am EST (5h behind GMT)
	# New to limit script to run only between these times - except weekends
	
	
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
# If it contains a regular expression - get rid of it
	my ($drugName) = ($drugExp =~ m/^\(*(.+?)\[.+$/) ? $1 : $drugExp;
	print $drugName, "\n";
	
# Write drug names to text file
	print OUT_FILE $drugName, "\t", $drugExp;
	
	# Loops over array of Queries
	READ_QUERY_LOOP: for my $entry (@query)
	{
	
# Write search params to Log file
		print $entry, "\n";        
		
# Make use of LWP to make call to PubMed query website

        my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?term=$drugExp+AND+$entry+NOT+review[pt]";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$drugName, $entry\nError: " . $response->code . " " . $response->message, "\n";
        
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

# Close off new line of data in text file with newline
	print OUT_FILE "\n";
	
}# End DRUG_LOOP

# Close the file we've opened
close(DFILE);
close(QFILE);
close(OUT_FILE);

