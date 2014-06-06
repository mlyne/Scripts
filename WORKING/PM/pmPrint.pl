#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use utf8;
use Text::Unidecode;
use XML::Twig::XPath;

my $usage = "Usage:terms2mesh.pl pubmed_xml\n

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
	my $asci = unidecode($_);
	#@entries = split(/\n\n/, $_);
	@entries = split(/\n\n/, $asci);
}

#my @asci = unidecode(@entries);

#print join('\n', @asci);

my $xmlHead = shift(@entries);
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
#   print $entry, "\n***\n";
  print "*** RECORD ***\n";

  my $twig=XML::Twig->new(
      twig_roots   => 
      {
		'Article/ArticleTitle'    => \&title,
		'JournalIssue/Volume'     => \&volume,
		'JournalIssue/Issue'      => \&issue,
		'DateCompleted/Year'      => \&pyear,
		'PubDate/Year'            => \&pyear,
		'Pagination/MedlinePgn'   => \&pages,
		'Journal/Title'           => \&journal_name,
		#'PublicationTypeList/PublicationType'  => \&pub_type,
		'Abstract/AbstractText'   => \&abstract,
		'Affiliation'       => \&address,
		'Author'       => \&author, 
      },
	      twig_handlers =>
	      { },
	      pretty_print => 'indented',  # output will be nicely formatted
	 ); 
	
  $twig->parse($entry); # build it
  
  $twig->purge;

	    #extract the abstract and uniquename assigned in Pubmed.pm
#	    my $abstract = $publication->uniquename();
#	    print STDOUT "The abstract is $abstract \n\n\n";
#	    my (@authors) = split /-----/ , $publication->title();
#	    my $title = shift(@authors);
#	    print STDOUT "The title is $title\n\n";
#	    $publication->title($title) ;
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
    return $title;
}



sub volume {
    my ($twig, $elt)= @_;
#    print "Volume: ", $elt->text, "\n";
    $twig->purge;
}


sub issue {
    my ($twig, $elt)= @_;
#    $publication->issue($elt->text) ;

    $twig->purge;
}


sub pyear {
    my ($twig, $elt)= @_;
    my $pyear = $elt->text;
#    $publication->pyear($pyear);

    $twig->purge;
}


sub pages {
    my ($twig, $elt)= @_;
#    $publication->pages($elt->text) ;

    $twig->purge;
}

sub journal_name {
    my ($twig, $elt)= @_;
#    $publication->series_name($elt->text) ;

    $twig->purge;
}

sub abstract {
    my ($twig, $elt)= @_;
#    $publication->uniquename($elt->text) ;

    $twig->purge
}

sub address {
    my ($twig, $elt)= @_;
#    $publication->uniquename($elt->text) ;
    print "ADDR: ", $elt->text, "\n";
    $twig->purge
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
    
    #append the authors to the 'title' field. 
    #Then extract the list and store in pubprop
#    $publication->title($publication->title() . "-----" . $author_data) ;
    print "AUTHOR: ", $author_data, "\n";
    $twig->purge
}
