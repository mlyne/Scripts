#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;

my $usage = "Usage:terms2mesh.pl pubmed_xml search_term_file\n";

unless ( $ARGV[1] ) { die $usage }

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

my %doubleTerms;

foreach my $entry (@addXMLheaders)
{
  my ($tiRef, $abstRef, $meshRef) = xmlTwig(\$entry);
  
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
    if ($allText =~ /\Q$searchTerm\E/)
    {
#	print "TERM MATCH: ", $searchTerm, "\n";
      push(@termHits, $searchTerm);
	#print $allText, "\n\n";
    }
   }

#  if (@meshHits)
#  {
  my @terms = sort(@termHits);
  
  while ( scalar(@terms) > 0)
  {
    my $term1 = shift(@terms);
  
    foreach my $count (0..$#terms)
    {
      my $dT = $term1."--".$terms[$count];
#    print $dT, "\n";
      $doubleTerms{$dT} += 1;
#    print $term1, "\t", $terms[$count], "\n";
    }
  }

  
  print "TERM HITS: ", join(", ", @termHits), "\n";
  print join("\n", @meshHits), "\n";
  print "--- RECORD ---\n";
#  }
}

foreach my $key (sort { $doubleTerms {$b} <=> $doubleTerms {$a}} keys %doubleTerms) 
{
  print "COUNT: ", $doubleTerms{$key}, "\tTERMS: ", $key, "\n";
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