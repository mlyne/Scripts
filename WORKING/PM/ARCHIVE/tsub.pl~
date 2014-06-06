#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;

my $usage = "Usage:MeSHConceptGen.pl mesh_tree_file " .
    "pubmed_xml\n";

unless ( $ARGV[2] ) { die $usage }

# Take input from the command line

my $meshTree = $ARGV[0];
my $xmlFile = $ARGV[1];
my $termFile = $ARGV[2];

my ($concept, $treePath);
my %conceptHash;
my %pathHash;

open(TREE_FILE, "< $meshTree")  || die "cannot open $meshTree: $!";

while (<TREE_FILE>)
{
  chomp;
  ($concept, $treePath) = split(/;/, $_);
  $conceptHash{$concept} = $treePath;
  $pathHash{$treePath} = $concept;
}

close(TREE_FILE);

open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";

$/ = undef;

my @entries;
my @lines;
my %meshCnt;
my @addXMLheaders;
my @sTerms;

while (<IFILE>)
{
	@entries = split(/\n\n/, $_);
}

my $xmlHead = shift(@entries);
my $xmlTail = "<\/PubmedArticleSet>";

# Close the file we've opened
close(IFILE);

open(TERM_FILE, "< $termFile")  || die "cannot open $termFile: $!";

while (<TERM_FILE>)
{
  chomp;
  (@sTerms) = split(/\n/, $_);
}

close(TERM_FILE);

$/ = "\n";

# recreate xml record
for (@addXMLheaders = @entries)
{
  $_ = $xmlHead. "\n". $_ . "\n" . $xmlTail;
}

#print "\nENTRY: \n", $_, "\n\n" foreach @addXMLhead; 

foreach my $entry (@addXMLheaders)
{
  my ($tiRef, $abstRef, $marrayRef) = xmlTwig(\$entry);
  
  my $title = $$tiRef->getValue;
#  print "TITLE: ", $title, "\n";
  
  my @abst = @$abstRef;
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 
  my $abstText;
  $abstText .= $_->getValue, foreach @abst;  
#  print "ABSTRACT: ", $abstText, "\n";
  
  my $allText = $title . $abstText;
  $allText =~ s/[^a-zA-Z\d\s]//g;
  $allText = lc($allText);
#  print $allText, "\n\n";
  
  my @meshHits;
  
  foreach my $mhRef (@$marrayRef)
  {
    my $meshTerm = $mhRef->getValue;
    push(@meshHits, $meshTerm);
#    print "MeSH: ", $meshTerm, "\n";
  }
  
  my $count = 0;
  my @termHits;
  
    foreach my $searchTerm (@sTerms)
    {
      if ($allText =~ /$searchTerm/) 
      {
#	print "TERM MATCH: ", $searchTerm, "\n";
	push(@termHits, $searchTerm);
	#print $allText, "\n\n";
	$count += 1;
      }
    }

  if ($count)
  {
  print "TERM HITS: ", join(", ", @termHits), "\n";
  print join("\n", @meshHits), "\n";
  print "--- RECORD ---\n\n";
  }

  
}


sub xmlTwig {

  my $entryRef = shift;
  my $entry = $$entryRef;
  
  my $twig = XML::Twig::XPath->new->parse($entry);

  my ($titlRef) = $twig->findnodes('//ArticleTitle');

#  my $title = $titlRef->getValue;

	my @abstRefs = $twig->findnodes('//AbstractText');
#	print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 

#	my @authors = $twig->findnodes('//LastName');
#	print "AUTHOR: ", $_->getValue, "\n" foreach @authors; 

#	my @mesh = $twig->findnodes('//MeshHeadingList/MeshHeading');
#	print "MESH: ", $_->getValue,"\n" foreach @mesh; 

  my @meshRef = $twig->findnodes('//DescriptorName');
  return (\$titlRef, \@abstRefs, \@meshRef);
  #print "MESH: ", $_->string_value,"\n" foreach @mesh;

}

# sub processMeSH {
# 
#   my $meshRef = shift;
#   my $conceptHashRef = shift;
#   my $pathHashRef = shift;
#   my @conceptTree;
#   
#   my $meshTerm = $$meshRef;
#   my %conceptHash = %$conceptHashRef;
#   my %pathHash = %$pathHashRef;
#   
#   if ( exists($conceptHash{$meshTerm}) )
#   {
#     my (@path) = split(/\./, $conceptHash{$meshTerm});
#     while (scalar(@path) > 0)
#     {
#       my ($node) = join(".", @path);
#       my $term = $pathHash{$node};
#	print "TERM: ", $term, "\n";
#       $meshCnt{$term} += '1';
#       print "MeSH: ", $pathHash{$node}, "\tTREE: ", $node, "\n";
#       push(@conceptTree, $pathHash{$node});
#       pop(@path);
#      }
#     return (\@conceptTree, \%meshCnt);
#     }
# }