#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;

my $usage = "Usage:meshXtractPM.pl pubmed_xml\n";

unless ( $ARGV[0] ) { die $usage }

# Take input from the command line

my $xmlFile = $ARGV[0];

open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";

$/ = undef;

my @entries;
my @addXMLheaders;

while (<IFILE>)
{
  @entries = split(/\n\n/, $_);
}

my $xmlHead = shift(@entries);
my $xmlTail = "<\/PubmedArticleSet>";

# Close the file we've opened
close(IFILE);

$/ = "\n";

for (@addXMLheaders = @entries)
{
  $_ = $xmlHead. "\n". $_ . "\n" . $xmlTail;
}


foreach my $entry (@addXMLheaders)
{
  my ($meshRef) = xmlTwig(\$entry);
  #print ref($tiRef), "\n";
  
  my @meshHits;
  
  foreach my $mhRef (@$meshRef)
  {
    my $meshTerm = $mhRef->getValue;
    push(@meshHits, $meshTerm);
#    print "MeSH: ", $meshTerm, "\n";
  }

  print join("\n", @meshHits), "\n";
  print "--- RECORD ---\n";
#  }
}


sub xmlTwig {

  my $entryRef = shift;
  my $entry = $$entryRef;
  
  my $twig = XML::Twig::XPath->new->parse($entry);

  my @meshRef = $twig->findnodes('//DescriptorName');
  return (\@meshRef);
  #print "MESH: ", $_->string_value,"\n" foreach @mesh;

}
