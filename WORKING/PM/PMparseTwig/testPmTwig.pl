#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use utf8;
#use Text::Unidecode;
use XML::Twig::XPath;

my $usage = "Usage:pmParse.pl pubmed_xml\n

Options:
\t-h\tThis help
\t-a\tPrint Authorsl\n
";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $optAuth);

getopts('ha', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"a"} and $optAuth++;

# Take input from the command line

my $xmlFile = $ARGV[0];

open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";

{ 
local $/ = undef;

my (@entries, @addXMLheaders, @sTerms);

while (<IFILE>)
{
	$_ =~ s/\<PubmedArticleSet\>\n\<PubmedArticle\>/\<PubmedArticleSet\>\n\n\n\<PubmedArticle\>/;
#	my $asci = unidecode($_);
#	@entries = split(/\n\n/, $asci);
	@entries = split(/\n\n/, $_);
}

#my @asci = unidecode(@entries);

#print join('\n', @asci);

my $xmlHead = shift(@entries);
#print "HEAD: ", $xmlHead, "\n";
my $xmlTail = "<\/PubmedArticleSet>";

# Close the file we've opened
close(IFILE);

local $/ = "\n";

# recreate xml record
#for (@addXMLheaders = @asci)
for (@addXMLheaders = @entries)
{
  $_ = $xmlHead . "\n". $_ . "\n" . $xmlTail;
}

#print "\nENTRY: \n", $_, "\n\n" foreach @addXMLhead; 

foreach my $entry (@addXMLheaders)
{

  my $twig=XML::Twig->new(
      twig_roots   => 
      {
		'Article/ArticleTitle'    => \&title,
		'Abstract/AbstractText'   => \&abstract,

      },
	      twig_handlers =>
	      { },
	 ); 
	
  $twig->parse($entry); # build it
  $twig->purge;

   print "-------------- --------------\n";
}
}

##########################################
#Functions for parsing the XML
##########################################

sub title {
    
    my ($twig, $elt)= @_;
    my $title = $elt->text;
    print "TITLE: ", $elt->text, "\n";
    $twig->purge;
}

sub abstract {
    my ($twig, $elt)= @_;
    print "ABST: ", $elt->text, "\n";
#    $publication->uniquename($elt->text) ;
    $twig->purge;
}
