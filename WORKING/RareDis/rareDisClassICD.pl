#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;
use Getopt::Std;

my $usage = "Usage: extractRareDis.pl pmTerm_counts orphanet_rareDis_xml

Options:
\t-h\tThis help
\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $noMesh, $meshStyle);

getopts('hns', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"n"} and $noMesh++;
defined $opts{"s"} and $meshStyle++;


# Take input files from the command line
my $xmlFile = $ARGV[0];

my $twig=XML::Twig->new();    # create the twig
$twig->parsefile( "$xmlFile"); # build it

my @disNode = $twig->findnodes('//Disorder');

our %disList;

print "DisShort\tDisease\tSynonyms\tICD\n";

foreach my $disorder (@disNode) {
  
  my $name = $disorder->first_child( 'Name' )->text;
  
  my $termShort = &mangle( $name );
  print $termShort, "\t", lc($name);
  
  my ( @synonyms, @synRefs );
  
  if ( $disorder->first_child( 'SynonymList[@count >= 1]' ) ) {
    my $synList = $disorder->first_child( 'SynonymList');
    @synRefs = $synList->children( 'Synonym' );
  }
  
  my (@syns, @synShorts);
  if (@synRefs) {
    foreach my $synRef (@synRefs) {
 
      my $syn = lc($synRef->text);
      push (@syns, $syn);
#      print "\t", $syn;
      my $synShort = &mangle( $syn );
      push (@synShorts, $synShort);
#      print "\t", $synShort;
      
    }
    print "\t", join("; ", @synShorts) if @syns;
  } else {
    print "\tNO SYNONYMS";
  }
  
   if ( $disorder->first_child( 'ExternalReferenceList' ) ) {
    my $extRefList = $disorder->first_child( 'ExternalReferenceList' ); 
    my @extRefs = $extRefList->children( 'ExternalReference' );
    
    my $icd;
    foreach my $ref ( @extRefs ) {
      my $refID = $ref->first_child('Source')->text;
#      print "\t", $ref->first_child('Source')->text;
#       if ( $ref->( 'Source[string()=~ /ICD10/]' ) ) {
      if ( $refID =~ /ICD10/ ) {
	$icd = $ref->first_child( 'Reference' )->text;
 	print "\t$icd";
 	last;
# 	my $icd = $ref->( 'Source' )->text;
# 	print "\t", "ICD: ", $icd;
      } else {
	next;
      }
    }
    print "\tNO ICD" unless ($icd);
  }
  
  print "\n";
#  print "TERMS: ", join("; ", @termSet ), "\n" if @termSet;
}


### Subs ###
sub mangle {
#  my @disTerms;
  
  my $term = shift;
#  my @terms = @{ $termRef };
  
#  foreach my $term (@terms) {
    my $lterm = lc($term);
    $lterm =~ s/.+?\>//; 
    $lterm =~ s/\<.+//; 
    $lterm =~ s/,.+ *ype//; 
    $lterm =~ s/ - .+//; 
    $lterm =~ s/, with .+//; 
    $lterm =~ s/ with.+//; 
    $lterm =~ s/\"//;
    $lterm =~ s/ type .+//; 
    $lterm =~ s/ due to.+//;
  
#     if (exists $disHitTest{$lterm} ) {
#       push(@disTerms, $lterm);
#     }
#   }
  
#  my $arrCnt = @disTerms;
  
#  if ($arrCnt) {
    return $lterm;
#   }
#   else {
#     return;
#   }
}

#my @para= $twig->children( 'para');