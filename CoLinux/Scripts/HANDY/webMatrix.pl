#!/usr/bin/perl -w

use LWP;
use strict;
#use Getopt::Long;
use Spreadsheet::WriteExcel::Big;

# Take input from the command line
my $drug_file = $ARGV[0];
my $query_file = $ARGV[1];
my $excel_file = $ARGV[2];

# Shortcircuit "if:then:else" operator
my $dispmax = 1;

### Configuring an Excel Workbook ###
my $workbook  = Spreadsheet::WriteExcel::Big->new("$excel_file.xls");
my $worksheet = $workbook->add_worksheet('CoOccurrance');
my $worksheet2 = $workbook->add_worksheet('Filter');

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

# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";
open(OUT_FILE, "> $excel_file.txt") || die "cannot open $excel_file: $!\n";
open(OUT_FILE_HTML, "> $excel_file.html") || die "cannot open $excel_file: $!\n";

print OUT_FILE_HTML <<TXT_HTML;
<html>
<head>
<title>Results of SearchLITE (Copyright &copy; 2003, 2004 Arakis Ltd.)</title>
</head>
<BODY text=#000000 vLink=#9F79EE link=#8A2BE2 bgColor=white>

<TABLE borderColor=#9966ff cellSpacing=0 borderColorDark=#9966ff cellPadding=0 width="100%" borderColorLight=#330099 border=0 hspace="0" vspace="0">
 <TBODY>
  <TR vAlign=top bgColor=#d7bcff>
   <TD width="15%" height=66>
    <DIV align=left>
     <IMG height=210 src="SearchLITElogo_tr.gif" alt="SearchLITE" width=210>
    </DIV>
   </TD>

   <TD vAlign=center width="50%" height=66>
   <FONT face="Arial, Helvetica, sans-serif" size=10>
     <B>
      <FONT color=#000000>&nbsp;&nbsp;&nbsp;Search</FONT><FONT color=white>LITE&nbsp;&nbsp;&nbsp;</FONT>
     </B>
    </FONT>
   </TD>
   
    <TD width="11%" height=66>
     <DIV align=right>
      <IMG height=66 src="Arakis1_sq.gif" alt="Arakis Logo" width=150>
     </DIV>
   </TD>      
  </TR>
 </TBODY>
</TABLE>

<B><A href="http://chem2.sis.nlm.nih.gov/chemidplus/chemidlite.jsp"TARGET="resource window">Search ChemID for Structure</A></B>

TXT_HTML



# Read queries into an array
chomp (my @query = <QFILE>); 

# Start position of results matrix
my $matrix_row = 2; 
my $filter_row = 7;

# Start position of Drugs header
my $drugColHeadStart = "A"; 

# Saving space - used for the hyperlink to PubMed and MeSH
my $pubMed = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&term=";
my $link = "+AND+";
my $noRev = "+NOT+review[pt]";
my $mesh = "http://www.nlm.nih.gov/cgi/mesh/2004/MB_cgi?term=";

### This section sets co-ordinates for the Query headers ###
# Start query headers at B - A is taken with drug headers
my $queryColHeadStart = "B"; 

### Header for column 1
$worksheet->write("A1", "SearchLITE");
$worksheet2->write("A6", "SearchLITE");
print OUT_FILE "SearchLITE";

print OUT_FILE_HTML <<TABLE_TITLE;
<div align=center>
<font size=+2 color=#9900CC>Matrix Results for SearchLITE</font><br>
<TABLE border 1>
<TR>
<TH colspan=11>
Some text Here for <font color=red>
MLYNE</font>
</TH></TR>
<tr><th>SearchLITE</th>
TABLE_TITLE

# Loop over Query file with counter to plot header co-ordinates
for my $query_header (@query)
{	
	my $queryRowHeadStart = 1;
	my $filterRowHeadStart = 6;
	my ($query_h) = ($query_header =~ m/^\(*(.+?)\[.+$/) ? $1 : $query_header;
	print OUT_FILE "\t", $query_h;
	print OUT_FILE_HTML "<th>", $query_h, "</th>";
	$worksheet->write("$queryColHeadStart$queryRowHeadStart", "$query_h");
	$worksheet2->write("$queryColHeadStart$filterRowHeadStart", "$query_h");
	$queryColHeadStart++;
	
#	$query_header =~ s/ /\+/g; #####
#	$query_header =~ s/\(/\\(/g; #### *** LOOK INTO BRACKETS IN SEARCHES ***
#	$query_header =~ s/\)/\\)/g; #####
}

# End of line for text file query headers
print OUT_FILE "\n";
print OUT_FILE_HTML "</tr>\n";

# Loops through Drug file
READ_DRUG_LOOP:while (<DFILE>)
{
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
# If it contains a regular expression - get rid of it
#	my ($drugName) = ($drugExp =~ m/^(.+)\[.+$/) ? $1 : $drugExp;
	my ($drugName) = ($drugExp =~ m/^\(*(.+?)\[.+$/) ? $1 : $drugExp;
	print $drugName, "\n";
	
# Write drug names to text file
	print OUT_FILE $drugName;
#	print OUT_FILE_HTML "<tr><th align=left>", $drugName, "</th>";
	print OUT_FILE_HTML "<tr><th align=left><A href=\"", "$mesh$drugName", "\"";
	print OUT_FILE_HTML "TARGET=\"resource window\">", $drugName, "</A></th>";
	
# Assigns a start column co-ordinate for results
	my $matrix_col = "B";
	
# Write our Drug names in the first column of the spreadsheet
# Start at row #2 as row #1 has query headers
#	$worksheet->write("$drugColHeadStart$matrix_row", "$drugName");
	$worksheet->write("$drugColHeadStart$matrix_row",  "$mesh$drugName",   "$drugName"              );
	$worksheet2->write("$drugColHeadStart$filter_row",  "$drugName");
	
	# Loops over array of Queries
	READ_QUERY_LOOP: for my $entry (@query)
	{

# Make use of LWP to make call to PubMed query website
        my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
        "&db=pubmed&term=$drugExp+AND+$entry+NOT+review[pt]&doptcmdl=docsum&dispmax=$dispmax";
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        #$response->is_success or die "failed";
        $response->is_success or print "$drugName, $entry\nError: " . $response->code . " " . $response->message, "\n";

        
#        $entry =~ s/\+\/ /g; ### *** HERE TOO ***
        
        my (@res, @reg); # Declare arrays for results processing

# Results are slurped back in HTML - we only want the Summary Text data
# Split each line into the array
        @res = split("\n", $response->content);

# Then use grep to retrieve the line with reference info
# feed into results array "@reg
#        @reg = grep /PMID/, @res;
#		my $no_item = grep /\>No items/, @res;
		my ($match) = grep /Total Results\"\>/, @res;		
		my $hitCount = "0";

		if ($match) 
		{
			($hitCount) = ($match =~ m/\>All: (\d+)\</);
		}
		
#		if ( (!$no_item) && (!$match) ) { $hitCount = 1 }
        
# Calculate co-occurrance hits from number of entries in @reg
#        my $hitCount = @reg; # ? scalar(@reg) : "0";   # CHECK THIS OUT!!!

# Write results and hyperlink to the spreadsheet
		$worksheet->write("$matrix_col$matrix_row", "$pubMed$drugExp$link$entry$noRev",   "$hitCount"              );
		$worksheet2->write("$matrix_col$filter_row", "$hitCount");
# Write Co-oc frequencies to Text file
		print OUT_FILE "\t", $hitCount;
		$entry =~ s/\"/\%22/g;
		$entry =~ s/\[/\%5b/g;
		$entry =~ s/\]/\%5d/g;
		print OUT_FILE_HTML "<td><A href=\"", "$pubMed$drugExp$link$entry$noRev", "\"\n";
		print OUT_FILE_HTML "TARGET=\"resource window\">", $hitCount, "</A></TD>\n";
		
# Add to column co-ordinates to assign next result position		
        $matrix_col++;

	}# End QUERY_LOOP
	
# Add to row co-ordinates to assign next result position		
	$matrix_row++;
	$filter_row++;
	
# Write end of line to text file
	print OUT_FILE "\n";
	print OUT_FILE_HTML "\n";
	
}# End DRUG_LOOP

print OUT_FILE_HTML <<TXT_HTML;
</TR>
</table>
</div>
</body>
</html><br>
TXT_HTML

# Close the file we've opened
close(DFILE);
close(QFILE);
close(OUT_FILE);
close(OUT_FILE_HTML);

### TEST ###
#$worksheet->write('A1', 'http://www.perl.com/'                );
#$worksheet->write('A3', 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&term=macrophage+AND+Trovafloxacin[title/abstract]
#', '5'   );
#$worksheet->write('A5', 'http://www.perl.com/', undef, $format);
#$worksheet->write('A7', 'mailto:jmcnamara@cpan.org', 'Mail me');

############

