#!/usr/bin/perl -w

use strict;
use LWP;

my $file = $ARGV[0];
my $out_file = $ARGV[1];

open(FILE, "< $file") || die "cannot open $file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

chomp (my @matrix = <FILE>);
my $info = shift(@matrix);
my $headers = shift(@matrix);
my $colTerms = shift(@matrix);
my @colTerms = split("\t", $colTerms);

print OUT_FILE $headers, "\n";
print OUT_FILE $colTerms, "\n";

my $queryCount = 1;

for my $entry (@matrix)
{
	chomp $entry;
	my @data = split("\t", $entry);
	my $drug = shift(@data);
	my $rowTerm = shift(@data);
	
	print OUT_FILE $drug, "\t", $rowTerm;
  
	my $headcount = 2;
	
	for my $val (@data)
	{
		if ($val == 12321)
		{
			my $sTerm = ($colTerms[$headcount]);
			my $subRef = &getPMhits(\$rowTerm, \$sTerm);
			my $hitCount = $$subRef;
			print OUT_FILE "\t", $hitCount;
			$queryCount++;
			
			if ($queryCount == 1000)
			{
				sleep 300;
				$queryCount = 1;
			}
						
		} else {
			print OUT_FILE "\t", $val;
		}
		$headcount++;
	}
    print OUT_FILE "\n";
    
}

sub getPMhits
{
	my $drugRef = shift;
	my $termRef = shift;
	my $drugExp = $$drugRef;
	my $term = $$termRef;
	
	#print $drugExp, "\t", $term, "\n";
	
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
	return \$hitCount;

}
