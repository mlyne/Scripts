#!/usr/bin/perl
use strict;
use warnings;
#use XML::Twig::XPath;
use XML::Twig;
use Getopt::Std;

my $usage = "Usage:terms2mesh.pl pubmed_xml search_term_file

Options:
\t-h\tThis help
\t-n\tsuppress MeSH terms
\t-s\tstyle MeSH terms [MESH TERMS: t1, t2, etc]

Use -n and -s together to suppress old MeSH output. 
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

$/ = undef;

open(TERM_FILE, "< $termFile")  || die "cannot open $termFile: $!";

our (@sTerms);
while (<TERM_FILE>)
{
  chomp;
  (@sTerms) = split(/\n/, $_);
}

close(TERM_FILE);

$/ = "\n";

my $twig = new XML::Twig( twig_handlers => { 'MedlineCitation' => \&call_pm });
$twig->parsefile( "$xmlFile" );

sub call_pm {

  my ($twig, $entry) = @_;
    
  my $pmid = $entry->first_child('PMID')->text;
  my ($titlRef) = $entry->findnodes('//ArticleTitle');
  my @abstRefs = $entry->findnodes('//AbstractText');
  my @substRefs = $entry->findnodes('//Chemical');
  my @meshRef = $entry->findnodes('//DescriptorName');
  
  &process_pm($pmid, $titlRef, \@abstRefs, \@substRefs, \@meshRef);
  #print "MESH: ", $_->string_value,"\n" foreach @mesh;

  $twig->purge();
  
}

sub process_pm
{
  my ($pmidRef, $tiRef, $abstRef, $substRefs, $meshRef) = @_;
  #print ref($tiRef), "\n";
  
  my $pmid = $pmidRef;
  
#  my $pmid = $$pmidRef->getValue;
  
  my $title = (ref($tiRef) eq "REF") ? $$tiRef->text : "NO TITLE"; 
  #if (ref($ref_firstArray) eq "ARRAY");

  my @abst = @$abstRef;
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 
  my ($abstText, $allText);
 
  $abstText .= $_->text, foreach @abst;  
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
  $allText =~ s/[\{\}\[\]\(\):;!\?,\.\>\<\#\\\/\%\"\=\*\|\&]/ /g; # strip punctuation (\')
  $allText =~ s/&gt//g;	# character codes
  $allText =~ s/&lt//g;	# character codes
  $allText =~ s/&quot//g;	# character codes
  $allText =~ s/&amp//g;	# character codes
  $allText =~ s/\s+/ /g;	# multiple whitespaces
#  print $allText, "\n***\n";

  my @substHits;
  
  foreach my $subRef ( @{ $substRefs } )
  {
    my $reg = $subRef->first_descendant('RegistryNumber')->text if $subRef;
    my $subst = $subRef->first_descendant('NameOfSubstance')->text if $subRef;
    push(@substHits, "$subst");
  }
  
  my @meshHits;
  
  foreach my $mhRef (@$meshRef)
  {
    my $meshTerm = $mhRef->text;
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
  print "PMID: ", $pmid, "\n";
  print "TERM HITS: ", join(", ", @noDupArr), "\n" if @termHits;
#  print join("\n", @meshHits), "\n" unless $noMesh;
  print "SUBST HITS: ", join("\; ", @substHits), "\n" if @substHits;
  print "MESH HITS: ", join("\; ", @meshHits), "\n" if @meshHits;
#  print "GRANT HITS: ", join("\; ", @uniqGrant), "\n" if @uniqGrant;  
  print "--- RECORD ---\n";
#  }
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
