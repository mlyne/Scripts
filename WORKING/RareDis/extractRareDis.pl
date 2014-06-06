#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;
use Getopt::Std;

my $usage = "Usage: extractRareDis.pl pmTerm_counts orphanet_rareDis_xml

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


# Take input files from the command line
my $disHits_file = $ARGV[0];
my $xmlFile = $ARGV[1];

open DISHITS_IN, "$disHits_file" or die "can't open $disHits_file\n";

my %disHitTest;

while (<DISHITS_IN>) {
  chomp $_;
  my $line = lc($_);
  my ($count, $dis) = split("\t", $line);
  $dis =~ s/\"//g;
  next unless (length($dis) >= 4);
  
  if ( ($count >= 5) && ($count < 20000) ) {
    $disHitTest{$dis} = $count;
  }
}

close (DISHITS_IN);

my $twig=XML::Twig->new();    # create the twig
$twig->parsefile( "$xmlFile"); # build it

my @disNode = $twig->findnodes('//Disorder');

our %disList;
my (%seen);

foreach my $disorder (@disNode) {
  my (@termArr, @termSet);
  my $term;
  
  my $name = $disorder->first_child( 'Name' )->text ;
  push (@termArr, $name);
  my $termRef = &mangle( \@termArr );
  
  if ($termRef) {
    @termSet = @{ $termRef };
    $term = $termSet[0];
    $seen{$term}++;
    $disList{$term}{$term}++;
#    print "Name: ", join("; ", @termSet), "\n";
  }
  
  my ( @synonyms, @synRefs );
  
  if ( $disorder->first_child( 'SynonymList[@count >= 1]' ) ) {
    my $synList = $disorder->first_child( 'SynonymList');
    @synRefs = $synList->children( 'Synonym' );
  }
  
  if (@synRefs) {
    foreach my $synRef (@synRefs) {
 
      push(@synonyms, $synRef->text);
      my $synRef = &mangle( \@synonyms );
      
      if ($synRef) {
	my @synTerms = @{ $synRef };
	
	if ($term) {
	  foreach my $syn ( @synTerms ) {
#	    print "TT: $term\t", $syn, "\n";
	    next if (exists $seen{$syn});
	    $disList{$term}{$syn}++;
	    $seen{$syn}++;
#	      push (@termSet, $syn);
	  }
	} else {
	  $term = shift @synTerms;
#	  print "TERM: $term\n";
	  next if (exists $seen{$term});
	  foreach my $syn ( @synTerms ) {
	    next if (exists $seen{$syn});
	    $disList{$term}{$syn}++;
	    $seen{$syn}++;
#	      push (@termSet, $syn);
	  }
	}
      }
      else { next };
    }
  }
#  print "TERMS: ", join("; ", @termSet ), "\n" if @termSet;
}

#  foreach my $key (keys %disList) {
#    print "\(\"", $key, "\"\[tiab\]";
#    foreach my $synonym (keys %{ $disList{$key} } ) {
#      print " OR ", "\"", $synonym, "\"\[tiab\]" if $synonym;
#    }
#    print "\)\n";
#  }
 
  foreach my $key (keys %disList) {
   print "\(", "\"$key\"\[tiab\]", " OR ", "\"$key\"\[mh\]";
   foreach my $synonym (keys %{ $disList{$key} } ) {
    next if ($synonym eq $key);
     print " OR ", "\"$synonym\"\[tiab\]", " OR ", "\"$synonym\"\[mh\]" if $synonym;
   }
   print "\)\n";
 }

### Subs ###
sub mangle {
  my @disTerms;
  
  my $termRef = shift;
  my @terms = @{ $termRef };
  
  foreach my $term (@terms) {
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
  
    if (exists $disHitTest{$lterm} ) {
      push(@disTerms, $lterm);
    }
  }
  
  my $arrCnt = @disTerms;
  
  if ($arrCnt) {
    return \@disTerms;
  }
  else {
    return;
  }
}

#my @para= $twig->children( 'para');