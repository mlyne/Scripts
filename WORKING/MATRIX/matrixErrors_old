#!/usr/bin/perl -w

use strict;
use LWP;

my $file = $ARGV[0];
open(FILE, "< $file") || die "cannot open $file: $!\n";

chomp (my @matrix = <FILE>);
my $info = shift(@matrix);
my $headers = shift(@matrix);
my $colTerms = shift(@matrix);
my @colTerms = split("\t", $colTerms);

print $headers, "\n";
print $colTerms, "\n";

for my $entry (@matrix)
{
	chomp $entry;
	my @data = split("\t", $entry);
	my $drug = shift(@data);
	my $rowTerm = shift(@data);
	
	print $drug, "\t", $rowTerm;
  
	my $count = 2;
	
	for my $val (@data)
	{
		if ($val == 12321)
		{
			my $sTerm = ($colTerms[$count]);
			my $subRef = &getPMhits(\$rowTerm, \$sTerm);
			my $hitCount = $$subRef;
			print "\t", $hitCount;
		} else {
			print "\t", $val;
		}
		$count++;
	}
    print "\n";

}

sub getPMhits
{
	my $drugRef = shift;
	my $termRef = shift;
	my $drugExp = $$drugRef;
	my $term = $$termRef;
	
#	print $drugExp, "\t", $term, "\n";
	
	# Make use of LWP to make call to PubMed query website
	my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=pubmed&rettype=count&term=$drugExp" .
    "+AND+$term+NOT+review[pt]" .
    "&tool=matrixFix" .
    "&email=michaellyne\@arakis.com";
        
    my $agent    = LWP::UserAgent->new;
    my $request  = HTTP::Request->new(GET => $url);
    my $response = $agent->request($request);
    $response->is_success or print "$drugExp, $term\tError: " . 
    $response->code . " " . $response->message, "\n";
    sleep 3;

        
    my $res; # Declare array for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

    $res = $response->content;
    #print $response->content, "\n";
    my $valid = "true" if ($res =~ m/eSearchResult/);

# Then use grep to retrieve the line with reference info
# feed into $entry

	my ($hitCount) = defined $valid ? ($res =~ m/\<Count\>(\d+)\</) : ("12321");
	return \$hitCount;

}