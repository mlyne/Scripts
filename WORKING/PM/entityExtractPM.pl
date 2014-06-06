#!/usr/bin/perl
use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;
use LWP::Simple;
use LWP::UserAgent qw($ua get);

my $ua = new LWP::UserAgent;
my %geneList = ();
my %genesMesh = ();
my %meshList = ();
my %intGenes = ();

my $usage = "Usage:entityExtractPM.pl termsFile out_file

Format: ID 'tab' Terms
\n";

unless ( $ARGV[0] ) { die $usage }

my $termFile = $ARGV[0];
# my $outFile = $ARGV[1];

open(IFILE, "< $termFile") || die "cannot open $termFile: $!\n";

my ($id, $terms); 
while (<IFILE>) {
  chomp;
  ($id, $terms) = split(/\t/, $_);
  
  my $query = ($terms);
  my $respRef = pubmed_fetch_records(\$query);
  my $response = $$respRef;
  
#  print $response->content, "\n\n";

#get PMIDs from Pubmed
# my $response = 
# $ua->get('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=kretzler%20m[au]&maxdate=2009&mindate=2009');

my $pubXP = XML::XPath->new(xml => $response->content);

print "*** Tagged Sentences from NCIBI NLP Web Service for:\n$query\n***\n\n";

foreach my $pmidNode ($pubXP->find('//Id')->get_nodelist) {
	my $pmid = $pmidNode->string_value;
	print $pmid, "\n";
	
	# get tagged sentences from nlp.ncibi.org
#	http://nlp.ncibi.org/fetch?pmid=$pmid&tagger=nametagger&type=gene
	$response = $ua->get("http://nlp.ncibi.org/fetch?pmid=$pmid&tagger=nametagger&type=gene");
	$response->is_success or print "Error: " . 
	$response->code . " " . $response->message, "\n";
	
	my $nlpXP = XML::XPath->new(xml => $response->content);
	
	# print sentences 
	foreach my $sentenceNode ($nlpXP->find('//Sentence')->get_nodelist){
		print $sentenceNode->string_value . "\n";
	}
	print "____________________________________________________________________________________ 1\n";
	foreach my $geneNode ($nlpXP->find('//Gene')->get_nodelist) {
		my $geneIDList = $geneNode->find('@id')->string_value;
		my $geneSymbol = $geneNode->string_value;
		$geneList {$geneSymbol} = $geneIDList;
	} #foreach genenode
	
} # foreach pmidnode

print "*** Tagged Genes from Pubmed Abstracts ***\n\n";

# print the unique gene symbols and gene IDs
while(my ($key, $value) = each(%geneList)){
	print $key . " => " . $value . "\n";
}

# get MeSH terms for each GeneID
while(my ($key, $value) = each(%geneList)){
	my @ids = split(/,/,$value);
	
	# get the top 10 Gene2MeSH results for each GeneID and interacting genes from MiMI
	foreach (@ids) {
	
		# Gene2MeSH results
		$response = $ua->get("http://gene2mesh.ncibi.org/fetch?geneid=$_&limit=10");
		$response->is_success or print "Error: " . 
		$response->code . " " . $response->message, "\n";
		
		my $g2mXP = XML::XPath->new(xml => $response->content);		
		my @g2mNodeList = $g2mXP->find('//Descriptor/Name')->get_nodelist;
		
		# add the MeSH terms to the hash holding each gene name
		foreach my $g2mNode (@g2mNodeList) {
			if ($g2mNode) {
				my $meshDesc = $g2mNode->string_value;
				$genesMesh {$key} .= $meshDesc . ' | ';
				if (exists $meshList{$meshDesc}) {
					$meshList{$meshDesc}++;
				}
				else {
					$meshList{$meshDesc} = 1;	
				}
			}
		}#foreach $g2mNode		
		
		# MiMI Results
		$response = $ua->get("http://mimi.ncibi.org/MimiWeb/fetch.jsp?geneid=$_&type=interactions");
		$response->is_success or print "Error: " . 
		$response->code . " " . $response->message, "\n";
		
		my $mimiXP = XML::XPath->new(xml => $response->content);
		my $mimiNodeSet = $mimiXP->find('//InteractingGene');
		
		# add the interacting genes 
		foreach my $mimiNode ($mimiNodeSet->get_nodelist) {
			my $geneIDNode =  $mimiXP->find('./GeneID', $mimiNode);
			my $geneSymbolNode =  $mimiXP->find('./GeneSymbol', $mimiNode);
			$intGenes {$key} .= $geneSymbolNode->string_value . " (" . $geneIDNode->string_value . ")" . ',';
		}#foreach miminode
	}#foreach ids
}#while geneList

print "____________________________________________________________________________________ 2\n";

# print sorted MeSH descriptors and counts

print "*** Top MeSH terms for Genes Tagged in Abstracts ***\n\n";

foreach my $key (sort hashValueAscendingNum (keys(%meshList))) {
	if ($meshList{$key} > 2) {
   		print "$key => $meshList{$key}\n";
	}
}

print "____________________________________________________________________________________ 3\n";

print "*** Interacting Genes from MiMI ***\n\n";

# print the gene symbols and the interacting genes
while(my ($key, $value) = each(%intGenes)){
	print $key . 
	"\n_________________________________________________________________ 4\n" . 
	$value . "\n\n";
}

} # end while IFILE

exit(1);

sub pubmed_fetch_records {
    my $qRef = shift;
    my $query = $$qRef;

    my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
    my $db = "pubmed";
    my $tool = "&tool=entityExtractPM";
    my $email = "&email=mlyne.careers\@gmail.com";

    # Search for IDs of articles matching query.
    print "SEARCHING REMOTE DATABASE WITH QUERY: $query\n";
    my $esearch = "$utils/esearch.fcgi?" . 
                 "db=$db&retmax=1000&usehistory=y&term=";
                 
    my $qString = "$esearch$query$tool$email";
    
    my $agent    = LWP::UserAgent->new;
    my $request  = HTTP::Request->new(GET => $qString);
    my $response = $agent->request($request);
    $response->is_success or print "Error: " . 
    $response->code . " " . $response->message, "\n";
    
#    print $response->content, "\n";
    
    $response->content =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
#    $response->content =~ m|<eSearchResult><Count>(\d+)</Count>|s;

    my $Count    = $1;
    my $QueryKey = $2;
    my $WebEnv   = $3;
    
    print "Number of records found: $Count\n";
#    print OUT_FILE "Number of records found: $Count\n";
    
    return unless $Count;
##    return; # for testing primary searches
    
    ### apply thresholds to publications returned ###
    
#    if ($Count >250) {
    if ($Count >1000) {
     print "Publication count $Count out of scope (scope: count < 1000)\n";
     return;
    }
    
    ### relaxed thresholds when searching with individual countries
#     if (($Count <= 15) || ($Count >200)) {
#     print "Publication count $Count out of scope (scope: 15 >= count < 200)\n";
#     return;
#     }
  return \$response;
}

sub hashValueAscendingNum {
   $meshList{$b} <=> $meshList{$a};
}