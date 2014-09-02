#!/usr/bin/perl
use strict;
use warnings;
#use XML::Twig::XPath;
use XML::Twig;
use Getopt::Std;

# Print unicode to standard out
binmode(STDOUT, 'utf8');

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
  my $article = $entry->first_child('Article');
    
  my $pmid = $entry->first_child('PMID')->text;
  my ($titlRef) = $article->first_child('ArticleTitle');
  my @abstRefs = $entry->findnodes('//AbstractText');
  my @substRefs = $entry->findnodes('//Chemical');
  my @meshRef = $entry->findnodes('//DescriptorName');
  my @authRef = $entry->findnodes('//Author');
  my @kwRef = $entry->findnodes('//Keyword');
  
  &process_pm($pmid, $article, $titlRef, \@abstRefs, \@substRefs, \@meshRef, \@authRef, \@kwRef);
  #print "MESH: ", $_->string_value,"\n" foreach @mesh;

  $twig->purge();
  
}

sub process_pm
{
  my ($pmid, $articRef, $tiRef, $abstRef, $substRefs, $meshRef, $authRef, $kwRef) = @_;
  #print ref($tiRef), "\n";
  
  my $pubnYr = $articRef->first_descendant('PubDate')->first_child->text;
  my $journal = "";
  if ( $articRef->first_descendant('ISOAbbreviation') ) {
    $journal = $articRef->first_descendant('ISOAbbreviation')->text;
  }
  
  my $volume = "";
  if ($articRef->first_descendant('Volume')) {
    $volume = $articRef->first_descendant('Volume')->text;
  }
  
  my $pages = "";
  if ($articRef->first_descendant('MedlinePgn')) {
	$pages = $articRef->first_descendant('MedlinePgn')->text;
  }
  
  my $cite;
  if ($journal) {
    $cite = "$journal, \($pubnYr\) $volume\:$pages";
#  print "\n\n *** $cite *** \n\n";
  } else {
    $cite = "NO CITATION \($pubnYr\)";
  }
  
#  my $title = (ref($tiRef) eq "REF") ? $$tiRef->text : "NO TITLE"; 
  my $title = ($tiRef) ? $tiRef->text : "NO TITLE"; 
  #if (ref($ref_firstArray) eq "ARRAY");

  my @abst = @$abstRef;
#  print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 
  my ($abstText, $allText);
 
  $abstText .= $_->text, foreach @abst;
#  print "ABSTRACT: ", $abstText, "\n";

  $abstText = ($abstText) ? $abstText : "NO ABSTRACT";

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

  my @authorlist;
  foreach my $author (@{ $authRef } ) {
    	# some authors have <CollectiveName>; most don't
    
    my $lastname=$author->first_child('LastName')->text if $author->first_child('LastName');
    my $initials=$author->first_child('Initials')->text if $author->first_child('Initials'); 
    my $collective=$author->first_child('CollectiveName')->text if $author->first_child('CollectiveName');
    my $foreN=$author->first_child('ForeName')->text if $author->first_child('ForeName');
    my $firstN=$author->first_child('FirstName')->text if $author->first_child('FirstName');
    if (!$initials) {  $initials=$foreN || $firstN }
    
    my $author_data = $lastname ." " . $initials if ($lastname && $initials); 
    
    if ((!$lastname) && ($collective)) { 
      $author_data = $collective; 
    } else {
      $lastname = "NO_LAST_NAME";
    }
    
     push( @authorlist, $author_data);
    }

		
    my $authors = "";
    for (my $loop=0; $loop < @authorlist; ++$loop) {
	$authors .= $authorlist[$loop];
	
	if ($loop < (@authorlist - 1)) {
	  	$authors .= ", ";
	}
    }
    
      $authors = ($authors) ? $authors : "NO AUTHORS";

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
  
  my @kwHits;
  foreach my $keywRef (@$kwRef)
  {
    my $keyword = $keywRef->text;
    push(@kwHits, $keyword);
#    print "KW: ", $keyword, "\n";
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
  print $pmid, "\t", 
    $cite, "\t",
    $title, "\t", 
    $abstText, "\t", 
    $authors, "\t";

  if (@termHits) {
    print join("; ", @noDupArr), "\t";
    } else {
      print "NO TERMS\t";
    }
#  print join("\n", @meshHits), "\n" unless $noMesh;

  if (@substHits) {
    print lc( join("\; ", @substHits) ), "\t";
  } else {
    print "NO SUBST\t";
  }
  
  if (@meshHits) {
    print lc( join("\; ", @meshHits) ), "\t"; 
  } else {
    print "NO MESH\t";
  }
  
  if (@kwHits) {
    print lc( join("\; ", @kwHits) ), "\n"; 
  } else {
    print "NO KW\n";
  }
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
