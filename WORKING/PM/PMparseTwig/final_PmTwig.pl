#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use utf8;
use Text::Unidecode;
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

$/ = undef;

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

$/ = "\n";

# recreate xml record
#for (@addXMLheaders = @asci)
for (@addXMLheaders = @entries)
{
  $_ = $xmlHead . "\n". $_ . "\n" . $xmlTail;
}

#print "\nENTRY: \n", $_, "\n\n" foreach @addXMLhead; 

foreach my $entry (@addXMLheaders)
{
#   print "***\n", $entry, "\n***\n";
#  print "*** RECORD ***\n";

#  my $asciEntry = unidecode($entry);

  my $twig=XML::Twig->new(
      twig_roots   => 
      {
		'Article/ArticleTitle'    => \&title,
		#'JournalIssue/Volume'     => \&volume,
		#'JournalIssue/Issue'      => \&issue,
		#'DateCompleted/Year'      => \&pyear,
		#'PubDate/Year'            => \&pyear,
		#'Pagination/MedlinePgn'   => \&pages,
		#'Journal/Title'           => \&journal_name,
		#'PublicationTypeList/PublicationType'  => \&pub_type,
		'Abstract/AbstractText'   => \&abstract,
#		'Affiliation'       => \&address,
#		'Author'       => \&author, 
      },
	      twig_handlers =>
	      { },
	      #pretty_print => 'indented',  # output will be nicely formatted
	 ); 
	
  $twig->parse($entry); # build it
#  $twig->parse($asciEntry); # build it

#  $twig->flush;
  $twig->purge;

   print "-------------- --------------\n";
}

##########################################
#Functions for parsing the XML
##########################################

sub title {
    
    my ($twig, $elt)= @_;
    my $title = $elt->text;
    print "TITLE: ", $elt->text, "\n";
    $twig->purge;
#    return $title;
}



# sub volume {
#     my ($twig, $elt)= @_;
# #    print "Volume: ", $elt->text, "\n";
#     $twig->purge;
# }
# 
# 
# sub issue {
#     my ($twig, $elt)= @_;
# #    $publication->issue($elt->text) ;
# 
#     $twig->purge;
# }
# 
# 
# sub pyear {
#     my ($twig, $elt)= @_;
#     my $pyear = $elt->text;
# #    $publication->pyear($pyear);
# 
#     $twig->purge;
# }
# 
# 
# sub pages {
#     my ($twig, $elt)= @_;
# #    $publication->pages($elt->text) ;
# 
#     $twig->purge;
# }
# 
# sub journal_name {
#     my ($twig, $elt)= @_;
# #    $publication->series_name($elt->text) ;
# 
#     $twig->purge;
# }

sub abstract {
    my ($twig, $elt)= @_;
    print "ABST: ", $elt->text, "\n";
#    $publication->uniquename($elt->text) ;
    $twig->purge;
}

sub address {
    my ($twig, $elt)= @_;
#    $publication->uniquename($elt->text) ;
    print "ADDR: ", $elt->text, "\n";
    $twig->purge;
}

sub author {
    my ($twig, $elt)= @_;
    
    my $lastname=$elt->children_text('LastName');
    my $initials=$elt->children_text('Initials');  
    my $collective=$elt->children_text('CollectiveName');
    #sometimes the firstname has no initials but full first name 'ForName'..
  
    if (!$initials) {  $initials=$elt->children_text('ForeName') || $elt->children_text('FirstName') ; }
    
    my $author_data=  $lastname ." " . $initials ; 
    if ((!$lastname) && ($collective)) { $author_data = $collective; }
    
    print "AUTHOR: ", $author_data, "\n";
    $twig->purge;
}
