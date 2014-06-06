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

# Saving space - used for the hyperlink to PubMed and MeSH
#my $pubMed = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&term=";
#my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?db=pubmed&term=";
my $link = "+AND+";
my $noRev = "+NOT+review[pt]";
my $mesh = "http://www.nlm.nih.gov/cgi/mesh/2004/MB_cgi?term=";

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
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
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

# Make use of LWP to make call to PubMed query website
#        my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
#        "&db=pubmed&term=$drugExp+AND+$entry+NOT+review[pt]&doptcmdl=docsum&dispmax=$dispmax";
        my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?" .
        "term=$drugExp+AND+$entry+NOT+review[pt]";        
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$drugName, $entry\nError: " . $response->code . " " . $response->message, "\n";

        
        my (@res, @reg); # Declare arrays for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array
###        @res = split("\n", $response->content);
        @res = split(/<DbName>/, $response->content);

# Then use grep to retrieve the line with reference info
# feed into results array "@reg

my ($entry) = grep /PubMed/, @res;
my ($hitCount) = ($entry =~ m/\<Count\>(\d+)\</);
        
# Calculate co-occurrance hits from number of entries in @reg


# Write Co-oc frequencies to Text file
		print OUT_FILE "\t", $hitCount;
		$entry =~ s/\"/\%22/g;
		$entry =~ s/\[/\%5b/g;
		$entry =~ s/\]/\%5d/g;


	}# End QUERY_LOOP
	

# Write end of line to text file
	print OUT_FILE "\n";
	
}# End DRUG_LOOP

# Close the file we've opened
close(DFILE);
close(QFILE);
close(OUT_FILE);


