#!/usr/bin/perl -w

use LWP;
use strict;
use Getopt::Long;

my $usage = "Usage: .\/coMed.pl --options in_file \"PubMed Query\" [maxHits]

Used for co-occurance searching of the Entrez pubMed database
./coMed <options> file \"query\" 10 

File format: in_file
List of search terms eg. Acebutolol
Terms and pubMed fields eg. Acebutolol[title/abstract]

Supported Queries:
Enclosed by \"\" with terms and operators separated by '+'
eg. \"AND+inflammation\"
    \"AND+(IL1+OR+IL2)\"
     supports truncation using \* eg. \"AND+inflammat\*\"
     support for quoted phrases eg. \"AND+\\\"collagen-induced+arthritis\\\"\"
     
MaxHits = number of records to display (defaults is 10)

Options:
\t--help           This list
\t--stat           Query term one vs. medLine Hits (tab delim)
\t--pmid           Query term one vs. PubMed Ids (Fasta format)
\t--ref            Query term one vs. titles/ref/pmid (Fasta format)
\t--dis            Number of entries to display (dependant on MaxHits)

\n";

#unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $resStat, $resPmid, $resRef, $resAll, $resTab, $resDis);

#'dis=i' in options allows option to be followed by an integer
GetOptions(\%opts, 'help', 'stat', 'pmid', 'all', 'ref', 'tab', 'dis=i');
defined $opts{"help"} and die $usage;

defined $opts{"stat"} and $resStat++;
defined $opts{"pmid"} and $resPmid++;
defined $opts{"ref"} and $resRef++;
defined $opts{"all"} and $resAll++;
defined $opts{"tab"} and $resTab++;
defined $opts{"dis"} and $resDis = $opts{"dis"};

# Take input from the command line
my $file = $ARGV[0];
my $query = $ARGV[1];

# Shortcircuit "if:then:else" operator
my $dispmax = ($ARGV[2]) ? $ARGV[2] : 10;

open(FILEO, "< $file") || die "cannot open $file: $!\n";

my $count;

# Loops through file
READ_LOOP:while (<FILEO>)
{
	my (@res, @reg);
	$count++;
	chomp;
	my $drugExp = $_;
	my ($drugName) = $drugExp =~ m/^(.+)\[.+$/; 
#	print $drugName, "\n";
#	print $drugExp, "\n";

# Make use of LWP to make call to PubMed query website
	my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search" .
	"&db=pubmed&term=$drugExp+$query&doptcmdl=docsum&dispmax=$dispmax";
	my $agent    = LWP::UserAgent->new;
	my $request  = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	$response->is_success or die "failed";
	
# Results are slurped back in HTML - we only want the Summary Text data
# Split each line into the array
	@res = split("\n", $response->content);
	
# Then use grep to retrieve the line with reference info
# feed into results array "@reg
	@reg = grep /PMID/, @res;

# Process results through a subroutine	
# Pass values as references so that they can be accessed separately from @_
	results_out(\@reg, \$drugName, \$drugExp, \$count);



}
# Close the file we've opened
close(FILEO);

###### Results Subroutine ######

sub results_out
{
# Retrieve references from @_ 
my ($arrRef, $drugRef, $expRef, $countRef)  = @_;

# Derefence
my @results = @$arrRef;
my $drugName = $$drugRef;
my $drugExpr = $$expRef;
my $drgCount = $$countRef;

# print $drugExpr, "\t", $query, "\n";

# Make a count of hits
my $hitCount = (scalar(@results)) ? scalar(@results) : "0";

# Process Stats output format if --stat used
print $drugName, "\t", $hitCount, "\n" if $resStat;

# Number of hits to display
# Reset value if we ask for more than available
my $limit = ($resDis) ? "$resDis" : @results;
if ($limit > @results) { $limit = @results }

# Default values for when we have no hits
my $tit = "No Hits";
my $journ = "No Hits";
my $pmid = "No Hits";



# Process references if --ref used
if ($resRef)
{
	print ">", $drugName, "\n";
	if (@results)
	{	
		foreach (my $i = 0; $i < $limit; $i++)
		{
			# Pattern match title, journal ref and PMID
			my ($tit) = $results[$i] =~ /<td colspan="2">(.+?)<br>/;
			my ($journ)= $results[$i] =~ /<br><font size="-1">(.+?) <br>/;
			my ($pmid)= $results[$i] =~ /<br>PMID: (.+?) \[Pub.+$/;
		
			print "Title:\t", $tit, "\n";
			print "Journal:\t", $journ, "\n";
			print "PubMed ID:\t", $pmid, "\n";
		}
	} else { print "No Hits\n" } # For queries which return no results
		
	print "\n";	
} # End Reference output

# Reset number of hits to display
$limit = $resDis if ($resDis);

# Process PMIDs if --pmid used
if ($resPmid)
{
	print ">", $drugName, "\n";
	if (@results)
		{
		foreach (my $i = 0; $i < $limit; $i++)
			{
			my ($pmid)= $results[$i] =~ /<br>PMID: (.+?) \[Pub.+$/;
			print $pmid, "\n";
			}
		} else { print "No Hits\n" } # For queries which return no results
		
	print "\n";	
} # End PMID output

} # End sub results

sub excel
{

}
