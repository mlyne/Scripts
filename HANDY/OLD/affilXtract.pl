#!/usr/bin/perl
use strict;
use warnings;
#use Getopt::Std;
use XML::Twig::XPath;

my $usage = "Usage:affilXtract.pl pubmed_xml\n";

unless ( $ARGV[0] ) { die $usage }

my $xmlFile = $ARGV[0];

open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";

$/ = undef;

my @entries;

while (<IFILE>)
{
	@entries = split(/\n\n/, $_);
}
close(IFILE);

foreach my $entry (@entry)
{
  my ($affilRef) = xmlTwig(\$entry);
  my $affiliation = $tiRef->getValue;
  print "AFFIL: ", $affilation, "\n";
  }
  
sub xmlTwig {

  my $entryRef = shift;
  my $entry = $$entryRef;
  
  my $twig = XML::Twig::XPath->new->parse($entry);

  my ($affilRef) = $twig->findnodes('//Affiliation');

  return ($affilRef);

}