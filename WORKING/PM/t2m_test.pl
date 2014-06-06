#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use XML::Twig::XPath;

my $usage = "Usage:terms2mesh.pl pubmed_xml search_term_file\n

Options:
\t-h\tThis help
\t-a\tPrint Authorsl\n
";

unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $optAuth);

getopts('ha', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"a"} and $optAuth++;

# Take input from the command line

my $xmlFile = $ARGV[0];
my $termFile = $ARGV[1];


open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";

$/ = undef;

my @entries;
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
  my ($tiRef, $abstRef, $meshRef, $authRef) = xmlTwig(\$entry);
  
  my $title = $$tiRef->getValue;
#  print "TITLE: ", $title, "\n";
  
  my @abst = @$abstRef;
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 
  my ($abstText, $allText);
 
  $abstText .= $_->getValue, foreach @abst;  
#  print "ABSTRACT: ", $abstText, "\n";

  if ($abstText)
  {
    $allText = $title . $abstText;
    $allText =~ s/[^a-zA-Z\d\s]//g;
    $allText = lc($allText);
#  print $allText, "\n\n";
  } else 
  {
    $allText = $title;
    $allText =~ s/[^a-zA-Z\d\s]//g;
    $allText = lc($allText);
#    print "HERE:", $allText, "\n\n";
  }
  
  my @authors = @$authRef;
  
  my @meshHits;
  
  foreach my $mhRef (@$meshRef)
  {
    my $meshTerm = $mhRef->getValue;
    push(@meshHits, $meshTerm);
#    print "MeSH: ", $meshTerm, "\n";
  }

  my @termHits;
  
  foreach my $searchTerm (@sTerms)
  {
    if ($allText =~ /\b\Q$searchTerm\E\b/)
    {
#	print "TERM MATCH: ", $searchTerm, "\n";
      push(@termHits, $searchTerm);
	#print $allText, "\n\n";
    }
   }

  my ($noDupRef) = remDupTerm(\@termHits);
  my @noDupArr = @{$noDupRef};
  
#  if (@meshHits)
#  {
###  print "TERM HITS: ", join(", ", @noDupArr), "\n";
###  if ($optAuth) { print "AUTHORS: ", $_->getValue, "\n" foreach @authors }; 
###  print join("\n", @meshHits), "\n";
  print "--- RECORD ---\n";
#  }
}


sub xmlTwig {

  my $entryRef = shift;
  my $entry = $$entryRef;
  
  my $twig = XML::Twig::XPath->new->parse($entry);

  my ($titlRefs) = $twig->findnodes('//ArticleTitle');
#  print "TITLE: ", $_->getValue, "\n" ;
#  my $title = $titlRef->getValue;

	my @abstRefs = $twig->findnodes('//AbstractText');
#	print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 

	my @authRefs = $twig->findnodes('//AuthorList/Author');
	print "AUTHOR: ", $_->getValue, "\n" foreach @authRefs; 

	my @affilRef = $twig->findnodes('//Affiliation');
	print "ADDR: ", $_->getValue, "\n" foreach @affilRef;

#	my @mesh = $twig->findnodes('//MeshHeadingList/MeshHeading');
#	print "MESH: ", $_->getValue,"\n" foreach @mesh; 

  my @meshRefs = $twig->findnodes('//DescriptorName');
  return (\$titlRefs, \@abstRefs, \@meshRefs, \@authRefs, \@affilRef);
  #print "MESH: ", $_->string_value,"\n" foreach @mesh;

}

sub remDupTerm {

  my $arRef = shift;
  my @termSet = sort {length $a <=> length $b} @{$arRef};
#  print "START: ", join(", ", @termSet), "\n";
  my @noDup;

  while (scalar(@termSet) > 0)
  {
    my $testTerm = shift(@termSet);
    push(@noDup, $testTerm) unless grep {/\b\Q$testTerm\E\b/ } @termSet;
  }
#  print "NO DUP: ", join(", ", @noDup), "\n";
  return (\@noDup);
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