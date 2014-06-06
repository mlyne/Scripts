#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use XML::Twig::XPath;

my $usage = "Usage:terms2mesh.pl pubmed_xml search_term_file\n

Options:
\t-h\tThis help
\t-a\tPrint Abstract\n
\t-m\tPrint MeSH\n
";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $optAbst, $optMesh);

getopts('ha', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"a"} and $optAbst++;
defined $opts{"m"} and $optMesh++;

# Take input from the command line

my $xmlFile = $ARGV[0];

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

$/ = "\n";

# recreate xml record
for (@addXMLheaders = @entries)
{
  $_ = $xmlHead. "\n". $_ . "\n" . $xmlTail;
}

#print "\nENTRY: \n", $_, "\n\n" foreach @addXMLhead; 

foreach my $entry (@addXMLheaders)
{
  my ($tiRef, $abRef, $adRefs, $auRefs, $meRef) = xmlTwig(\$entry);
  
  print "*** RECORD ***\n";

#  print "TITLE: ", $$tiRef->getValue, "\n";

  if ($optAbst)
  {
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @$abRef; 
  }

  foreach my $addr (@$adRefs)
  {
#    print "ADDRESS: ", $addr->getValue, "\n";
  }

#  print "AUTHORS: ";

  foreach my $authors (@$auRefs)
  {
#    print $authors->getValue, ", ";
  }
  print "\n";

#  print "AUTH: ", join(',', $_->getValue), "\n" foreach @$auRefs;

  
  foreach my $mhRef (@$meRef)
  {
#    print "MeSH: ", $mhRef->getValue, "\n" if $optMesh;
  }

  print "--------  --------\n";
}

sub xmlTwig {

  my $entryRef = shift;
  my $entry = $$entryRef;
  
  my $twig = XML::Twig::XPath->new->parse($entry);

  my ($titlRef) = $twig->findnodes('//ArticleTitle');

  my @abstRefs = $twig->findnodes('//AbstractText');

  my @addrRef = $twig->findnodes('//Affiliation');

  my @authRefs = $twig->findnodes('//AuthorList/Author');
  
#  for my $node ( $twig->findnodes( '//AuthorList/LastName | //AuthorList/Initials | //Author/ForeName | //Author/FirstName | //Author/CollectiveName' ) ) {
  for my $node ( $twig->findnodes( '//LastName | //Initials ' ) ) {

      my $lastname = $node->text if $node->name eq q{LastName};
#      print $node->text if $node->name eq q{LastName};
#      print "last: ", $lastname, "\n";
#      my $forename = $node->text if $node->name eq q{ForeName};
#      my $firstname = $node->text if $node->name eq q{FirstName};
      my $initials = $node->text if $node->name eq q{Initials};
#      my $collective = $node->text if $node->name eq q{CollectiveName};
          
#      if (!$initials) { $forename || $firstname ; }
    
      my $author_data=  $lastname . " " . $initials ; 
#      if ((!$lastname) && ($collective)) { $author_data = $collective; }
    
      print "AUTHOR: ", $author_data, "\n";
  }


  #my @c = $_->findvalue('./a/');

  my @meshRefs = $twig->findnodes('//DescriptorName');

  $twig->purge;

  return (\$titlRef, \@abstRefs, \@addrRef, \@authRefs, \@meshRefs);

}
