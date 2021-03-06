#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;
use Getopt::Std;
use Data::Dumper;

my $usage = "Usage:parsePMxml.pl pubmed_xml search_term_file

Options:
\t-h\tThis help
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

open(TERM_FILE, "< $termFile")  || die "cannot open $termFile: $!";

$/ = undef;

my (@sTerms);

while (<TERM_FILE>)
{
  chomp;
  (@sTerms) = split(/\n/, $_);
}

close(TERM_FILE);

$/ = "\n";

my $twig = XML::Twig::XPath->new->parsefile($xmlFile);
my (@entries) = $twig->findnodes('//MedlineCitation');

#my $artNo = (@articles);
#print "ARTcnt: ", $artNo, "\n";

foreach my $entry (@entries) {
  print Dumper( $entry );

  my $pmid = $entry->first_descendant('PMID')->text;
  print "PMID:", $pmid, "\n" if $pmid;
  
  my $ti = $entry->first_descendant('ArticleTitle')->text;
  print "TI:", $ti, "\n" if $ti;

#  my ($titlRef) = $article->findnodes('//ArticleTitle');
  my @abstRefs = $entry->descendants('AbstractText');
  my @substRefs = $entry->descendants('Chemical');
  
  my @meshRefs = $entry->descendants('DescriptorName');
  
#  my $meshRef = $entry->findnodes('//DescriptorName');
#  my $grantRef = $entry->findnodes('//Grant');
  
  my $title = ($ti) ? $ti : "NO TITLE"; 
  #if (ref($ref_firstArray) eq "ARRAY");

#  my @abst = @{ $abstRefs };
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 

  my ($abstText, $allText);
  
  foreach my $ab (@abstRefs)
  {
    $abstText .= $ab->text;
  }
  
  my $abstract = ($abstText) ? $abstText : "NO ABST"; 
#  print "ABST: ", $abstract, "\n";
  
#  $abstText .= $_->getValue, foreach @abst;
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
  
  foreach my $subRef ( @substRefs )
  {
    my $reg = $subRef->first_descendant('RegistryNumber')->text if $subRef;
    my $subst = $subRef->first_descendant('NameOfSubstance')->text if $subRef;
    push(@substHits, "$subst");
  }
  
  my @meshHits;
  
  foreach my $mh ( @meshRefs )
  {
    my $mhTerm = $mh->getValue;
    push(@meshHits, $mhTerm);
#    print "MeSH: ", $mhTerm, "\n";
  }
  
#   foreach my $mhRef ( @{ $meshRef } )
#   {
#     my $meshTerm = $mhRef->getValue;
#     push(@meshHits, $meshTerm);
# #    print "MeSH: ", $meshTerm, "\n";
#   }
  
  my @grantHits;
  
#   foreach my $grRef ( @{ $grantRef } )
#   {
#     my $agency = $grRef->first_descendant('Agency')->text if $grRef;
#     my $cntry = $grRef->first_descendant('Country')->text if $grRef;
# #    print "GRANT: $agency:$cntry\n";
#     $cntry =~ s/United States/US/;
#     $cntry =~ s/United Kingdom/UK/;
#     push(@grantHits, "$agency:$cntry");
#   }
#   
#   my @uniqGrant = do { my %seen; grep { !$seen{$_}++ } @grantHits };

  my @termHits;
  
  foreach my $searchTerm (@sTerms) 
  {
#    print "TERM: ", $searchTerm, "\n";
    if ($allText =~ /\b\Q$searchTerm\E\b/) {
#'      print "TERM MATCH: ", $searchTerm, "\n";
      push(@termHits, $searchTerm);
#    print $allText, "\n\n";
    }
  }

  my ($noDupRef) = remDupTerm(\@termHits);
  my @noDupArr = @{$noDupRef};
  
#  if (@meshHits)
#  {
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
