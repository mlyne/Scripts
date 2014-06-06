#!/usr/bin/perl
use warnings;
use strict;
use XML::Twig::XPath;

my $file = $ARGV[0];
my $twig= new XML::Twig(TwigRoots => {MeshHeading => 1});
$twig->parsefile($file);
$twig->print;


#my $inFile = $ARGV[0];

#my $twig = XML::Twig::XPath->new->parse($inFile);

#my ($title) = $twig->findnodes('//Article/ArticleTitle');
#print $title->getValue,"\n";

#my @authors = $twig->findnodes('//Article/AuthorList/Author');
#print $_->getValue,"\n" foreach @authors; 
