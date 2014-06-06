#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;

my $usage = "Usage:MeSHConceptGen.pl mesh_tree_file " .
    "pubmed_xml\n";

unless ( $ARGV[1] ) { die $usage }

# Take input from the command line

my $meshTree = $ARGV[0];
my $xmlFile = $ARGV[1];

my ($concept, $treePath);
my %conceptHash;
my %pathHash;

open(TREE_FILE, "< $meshTree")  || die "cannot open $meshTree: $!";

while (<TREE_FILE>)
{
  chomp;
  ($concept, $treePath) = split(/;/, $_);
  $conceptHash{$concept} = $treePath;
  $pathHash{$treePath} = $concept;
}

close(TREE_FILE);

open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";

$/ = undef;

my @entries;
my @lines;
my %meshCnt;

while (<IFILE>)
{
	@entries = split(/\n\n/, $_);
}

shift(@entries);

# Close the file we've opened
close(IFILE);

$/ = "\n";

foreach my $entry (@entries)
{
	#print "\nNEW ENTRY: \n", $entry, "\nEND ENTRY\n\n";
#	$entry =~ s/[^[:ascii:]]//g;
	
	my $twig = XML::Twig::XPath->new->parse($entry);
	#$twig->parse( $entry );

	my ($title) = $twig->findnodes('//ArticleTitle');
	print "TITLE: ", $title->getValue,"\n";

#	my @abst = $twig->findnodes('//AbstractText');
#	print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 

#	my @authors = $twig->findnodes('//LastName');
#	print "AUTHOR: ", $_->getValue, "\n" foreach @authors; 

#	my @mesh = $twig->findnodes('//MeshHeadingList/MeshHeading');
#	print "MESH: ", $_->getValue,"\n" foreach @mesh; 

	my @mesh = $twig->findnodes('//DescriptorName');
#	print "MESH: ", $_->string_value,"\n" foreach @mesh;

        foreach my $mhRef (@mesh)
        {
	  my $meshTerm = $mhRef->getValue;
	  
          if ( exists($conceptHash{$meshTerm}) )
	  {
	    print "\n";
	    my (@path) = split(/\./, $conceptHash{$meshTerm});
	    my @conceptTree;
	    while (scalar(@path) > 0)
	    {
	      my ($node) = join(".", @path);
	      my $term = $pathHash{$node};
#	      print "TERM: ", $term, "\n";
	      $meshCnt{$term} += '1';
	      print "MeSH: ", $pathHash{$node}, "\tTREE: ", $node, "\n";
#	      push(@conceptTree, $pathHash{$node});
	      pop(@path);
	    }
#	    my @revConTree = reverse(@conceptTree);
#	    print "\nMAIN: ", $revConTree[0], "\n";	    
#	    print "CONCEPT: ", $revConTree[1], "\n";
	   }

        }
        
print "--- END ---\n\n";

}

foreach my $key (sort { $b <=> $a } values %meshCnt) 
{
  print "COUNT: ", $meshCnt{$key}, "\tKEY: ", $key, "\n"; 
#  print " VAL: ", $pathHash{$key}, "\tKEY: ", $key, "\n";
}

