#!/usr/bin/perl -w

use LWP;
use strict;
#use Getopt::Long;
use Spreadsheet::WriteExcel;

### Configuring an Excel Workbook ###
my $workbook  = Spreadsheet::WriteExcel->new("test.xls");
my $worksheet = $workbook->add_worksheet('CoOccurrance');

# Format the first column
#$worksheet->set_column('A:A', 30);
#$worksheet->set_selection('B1');

# Add a sample format
my $format = $workbook->add_format();
$format->set_size(12);
$format->set_bold();
$format->set_color('blue');
$format->set_underline();

### End Config ###


# Take input from the command line
my $drug_file = $ARGV[0];
my $query_file = $ARGV[1];

# Shortcircuit "if:then:else" operator
my $dispmax = ($ARGV[2]) ? $ARGV[2] : 1;

# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";

# Read queries into an array
chomp (my @query = <QFILE>); 

# Start position of results matrix
my $matrix_row = 2; 

# Start position of Drugs header
my $drugColHeadStart = "A"; 

# Saving space - used for the hyperlink to PubMed
my $pubMed = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&term=";
my $link = "+AND+";

### This section sets co-ordinates for the Query headers ###
# Start query headers at B - A is taken with drug headers
my $queryColHeadStart = "B"; 

# Loop over Query file with counter to plot header co-ordinates
for my $query_header (@query)
{	
	my $queryRowHeadStart = 1;
	$worksheet->write("$queryColHeadStart$queryRowHeadStart", "$query_header");
	$queryColHeadStart++;
	
	$query_header =~ s/ /\+/g; #####
#	$query_header =~ s/\(/\\(/g; #### *** LOOK INTO BRACKETS IN SEARCHES ***
#	$query_header =~ s/\)/\\)/g; #####
}

# Loops through Drug file
READ_DRUG_LOOP:while (<DFILE>)
{
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
# If it contains a regular expression - get rid of it
	my ($drugName) = ($drugExp =~ m/^(.+)\[.+$/) ? $1 : $drugExp;

# Assigns a start column co-ordinate for results
	my $matrix_col = "B";
	
# Write our Drug names in the first column of the spreadsheet
# Start at row #2 as row #1 has query headers
	$worksheet->write("$drugColHeadStart$matrix_row", "$drugName");
	
	# Loops over array of Queries
	READ_QUERY_LOOP: for my $entry (@query)
	{

# Make use of LWP to make call to PubMed query website
        my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
        "&db=pubmed&term=$drugExp+AND+$entry&doptcmdl=docsum&dispmax=$dispmax";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        #$response->is_success or die "failed";
        $response->is_success or print "$drugName, $entry\nError: " . $response->code . " " . $response->message;

        
#        $entry =~ s/\+\/ /g; ### *** HERE TOO ***
        
        my (@res, @reg); # Declare arrays for results processing

# Results are slurped back in HTML - we only want the Summary Text data
# Split each line into the array
        @res = split("\n", $response->content);

# Then use grep to retrieve the line with reference info
# feed into results array "@reg
#        @reg = grep /PMID/, @res;
		my $no_item = grep /\>No items/, @res;
		my ($match) = grep /um2">Item 1 of/, @res;		
		my $hitCount = "0";

		if ($match) 
		{
			($hitCount) = ($match =~ m/\>Item 1 of (\d+)\</);
		}
		
		if ( (!$no_item) && (!$match) ) { $hitCount = 1 }
        
# Calculate co-occurrance hits from number of entries in @reg
#        my $hitCount = @reg; # ? scalar(@reg) : "0";   # CHECK THIS OUT!!!

# Write results and hyperlink to the spreadsheet
		$worksheet->write("$matrix_col$matrix_row", "$pubMed$drugExp$link$entry",   "$hitCount"              );
		
# Add to column co-ordinates to assign next result position		
        $matrix_col++;

	}# End QUERY_LOOP
	
# Add to row co-ordinates to assign next result position		
	$matrix_row++;
	
}# End DRUG_LOOP

# Close the file we've opened
close(DFILE);
close(QFILE);

### TEST ###
#$worksheet->write('A1', 'http://www.perl.com/'                );
#$worksheet->write('A3', 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&term=macrophage+AND+Trovafloxacin[title/abstract]
#', '5'   );
#$worksheet->write('A5', 'http://www.perl.com/', undef, $format);
#$worksheet->write('A7', 'mailto:jmcnamara@cpan.org', 'Mail me');

############

