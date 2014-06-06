#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;
use Getopt::Std;

my $usage = "Usage:nmf_format.pl pubmed_xml search_term_file

\n";

unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $noMesh, $meshStyle);

getopts('hns', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"n"} and $noMesh++;
defined $opts{"s"} and $meshStyle++;


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
  $_ =~ tr/\x00-\x08\x0B\x0C\x0E-\x19//d;
  @entries = split(/\n\n/, $_);
}

#print "Header: ", $entries[0], "\n";
my $xmlHead = shift(@entries);
$xmlHead =~ s/xml version\=\"1.0\"/xml version\=\"1.0\" encoding\=\"UTF-8\"/;
#print "Header2: ", $xmlHead, "\n";
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

print "PMID\t", join("\t", @sTerms), "\n";

$/ = "\n";

# recreate xml record
for (@addXMLheaders = @entries)
{
  $_ = $xmlHead. "\n". $_ . "\n" . $xmlTail;
}

#print "\nENTRY: \n", $_, "\n\n" foreach @addXMLhead; 

foreach my $entry (@addXMLheaders)
{
  my ($pmidRef, $tiRef, $abstRef, $meshRef) = xmlTwig(\$entry);
  #print ref($tiRef), "\n";

  my $pmid = (ref($pmidRef) eq "REF") ? $$pmidRef->getValue : "NO PMID";
  
  print $pmid;
  
  my $title = (ref($tiRef) eq "REF") ? $$tiRef->getValue : "NO TITLE"; 
  #if (ref($ref_firstArray) eq "ARRAY");

  my @abst = @$abstRef;
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 
  my ($abstText, $allText);
 
  $abstText .= $_->getValue, foreach @abst;  
#  print "ABSTRACT: ", $abstText, "\n";

  if ($abstText)
  {
    $allText = $title . " " . $abstText;
    $allText =~ s/[^a-zA-Z\d\s\-]//g;
    $allText = lc($allText);
#  print $allText, "\n\n";
  } else 
  {
    $allText = $title;
    $allText =~ s/[^a-zA-Z\d\s\-]//g;
    $allText = lc($allText);
#    print "HERE:", $allText, "\n\n";
  }
  
  # added 1st dec 2011
  $allText =~ s/\n/ /g;
#  $allText =~ s/[^[:ascii:]]//g; # strip punctuation ## may be too severe on hyphens?
  $allText =~ s/[\{\}\[\]\(\):;!\?,\.\>\<\#\'\\\/\%\"\=\*\|\&]/ /g; # strip punctuation (\')
  $allText =~ s/&gt//g;	# character codes
  $allText =~ s/&lt//g;	# character codes
  $allText =~ s/&quot//g;	# character codes
  $allText =~ s/&amp//g;	# character codes
  $allText =~ s/\s+/ /g;	# multiple whitespaces
#  print $allText, "\n***\n";

  
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
      print "\t1";
    } else { print "\t0"; }
   }
print "\n";
#   my ($noDupRef) = remDupTerm(\@termHits);
#   my @noDupArr = @{$noDupRef};
#   
# #  if (@meshHits)
# #  {
#   print "TERM HITS: ", join(", ", @noDupArr), "\n";
#   print join("\n", @meshHits), "\n" unless $noMesh;
#   print "MESH HITS: ", join(", ", @meshHits), "\n" if $meshStyle;
#   print "--- RECORD ---\n";
#  }
}


sub xmlTwig {

  my $entryRef = shift;
  my $entry = $$entryRef;
  
  my $twig = XML::Twig::XPath->new->parse($entry);
  
  my ($pmidRef) = $twig->findnodes('//PMID');

  my ($titlRef) = $twig->findnodes('//ArticleTitle');

#  my $title = $titlRef->getValue;

	my @abstRefs = $twig->findnodes('//AbstractText');
#	print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 

#	my @authors = $twig->findnodes('//LastName');
#	print "AUTHOR: ", $_->getValue, "\n" foreach @authors; 

#	my @mesh = $twig->findnodes('//MeshHeadingList/MeshHeading');
#	print "MESH: ", $_->getValue,"\n" foreach @mesh; 

  my @meshRef = $twig->findnodes('//DescriptorName');
  return (\$pmidRef, \$titlRef, \@abstRefs, \@meshRef);
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
