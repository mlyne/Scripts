#!/usr/bin/perl
use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;
use LWP::UserAgent qw($ua get);

my $ua = new LWP::UserAgent;
my %geneList = ();
my %genesMesh = ();
my %meshList = ();
my %intGenes = ();

#get PMIDs from Pubmed
my $response = 
$ua->get('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=kretzler%20m[au]&maxdate=2009&mindate=2009');

my $pubXP = XML::XPath->new(xml => $response->content);

print "*** Tagged Sentences from NCIBI NLP Web Service for Mattias Kretzler's Publications in 2009 ***\n\n";

foreach my $pmidNode ($pubXP->find('//Id')->get_nodelist) {
	my $pmid = $pmidNode->string_value;
	
	# get tagged sentences from nlp.ncibi.org
	$response = $ua->get("http://nlp.ncibi.org/fetch?tagger=nametagger&type=gene&pmid=$pmid");
	my $nlpXP = XML::XPath->new(xml => $response->content);
	
	# print sentences 
	foreach my $sentenceNode ($nlpXP->find('//Sentence')->get_nodelist){
		print $sentenceNode->string_value . "\n";
	}
	print "____________________________________________________________________________________\n";
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


print "____________________________________________________________________________________\n";

# print sorted MeSH descriptors and counts

print "*** Top MeSH terms for Genes Tagged in Abstracts ***\n\n";

sub hashValueAscendingNum {
   $meshList{$b} <=> $meshList{$a};
}

foreach my $key (sort hashValueAscendingNum (keys(%meshList))) {
	if ($meshList{$key} > 2) {
   		print "$key => $meshList{$key}\n";
	}
}

print "____________________________________________________________________________________\n";

print "*** Interacting Genes from MiMI ***\n\n";

# print the gene symbols and the interacting genes
while(my ($key, $value) = each(%intGenes)){
	print $key . 
	"\n_________________________________________________________________\n" . 
	$value . "\n\n";
}

