#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;


use Getopt::Std;
#use BioPorter;

use feature ':5.12';
use open qw(:std :utf8);

# Print unicode to standard out
binmode(STDOUT, ":unix:utf8");
binmode(STDIN, 'utf8');
binmode(STDERR, 'utf8');

# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:ontologyBuilder.pl [-t| [-s|-x] |-h] pubmed_xml_file stop_words\n
Requires BioPorter.pm. Please contact me: mike\@unnayati.co.uk

NOTE*** BIOPORTER options removed for time being

Options:
\t-h\tThis help
\t-t\taccept text file as input
\t-s\tuse word stemming (porter)
\t-x\tXtreme stemming: stems stop words too\n
NOTE: Do not combine -s and -x. You have been warned!\n";

unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $text, $stem, $xtremStem);

getopts('htsx', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $text++;
defined $opts{"s"} and $stem++;
defined $opts{"x"} and $xtremStem++;

die "Do not combine -s with -x. Use -x instead.\n" if ($stem && $xtremStem);

# ./ontologyBuilder.pl file_xml.txt stopList | an_awk_filter >  out_file
# Takes a set of PubMed entries in XML.txt format
# and chops it up into one, two, three, and four word
# combinations. Next it Parses the list using a stopword file
# Options turn on word stemming but not usefl if you need to generate search terms

my $in_file = $ARGV[0];
my $stopWords = $ARGV[1];

open(STOP, "< $stopWords") || die "cannot open $stopWords: $!\n";
my %stopHsh = ();

while (<STOP>) {
  chomp;
#  $stopHsh{$_}++;
  $stopHsh{$_}++ unless $xtremStem;
### BioPorter dependency
#  my $stopStem = porter("$_") if $xtremStem;
#  $stopHsh{$stopStem}++ if $xtremStem;
}
close (STOP);

open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
my $words;

## Parse Title & Abstracts from XML ##
# Could be done quicker with XML parser but little gained and extra module required
unless ($text) {
  while (<IFILE>) {
    chomp;
    my $line = $_;
    if ($line =~ (/ArticleTitle/) ) {
	my $title = $line;
	$title =~ s/^\s+//g;
	$title =~ s/[\<\/\>]//g;		
	$title =~ s/ArticleTitle//g;
	$words .= $title;
  #	print $title, "\n***\n\n";
    }
	  
    if ($line =~ (/AbstractText/) ) {
	my $abst = $line;
	$abst =~ s/^\s+//g;
	$abst =~ s/ Label\=.+?\"\>//g;
	$abst =~ s/[\<\/\>]/ /g;		
	$abst =~ s/AbstractText//g;
	$abst =~ s/ \d+\. //g;
	$abst =~ s/\d+,\d+//g;
	$words .= $abst;
  #	print $abst, "\n***\n\n";
	}
  }
}

# If input is a text file
if ($text) {
  while (<IFILE>) {
    $words .= $_;
    $words =~ s/^\s+//g;
   }
}

close (IFILE);
#print $words, "\n";

# Pre-process text to lc and strip some punctuation
my $big_string = lc($words);
$big_string =~ s/\n/ /g;
#$big_string =~ s/[^[:ascii:]]//g; # strip non-ascii
#$big_string =~ s/[^a-zA-Z\d\s]//g; # strip non letter number
$big_string =~ s/[\{\}\[\]\(\)\:\;\!\?\,\.\>\<\#\\\/\%\"\=\*\|\&\@]/ /g; # strip special characters (temp removed \')
$big_string =~ s/ - |- | -/ /g;
$big_string =~ s/\&gt|\&lt|\&quot|\&amp//g;	# character codes
$big_string =~ s/\s+/ /g;	# multiple whitespaces

#print $big_string, "\n";

my @words = split(/ /, $big_string);

my (@singles, %termCount, @stemmed);

### BioPorter dependency
# Stringent stemming - stems Stop words. 
# Warning excludes key terms eg. disease: diseases / diseased -> diseas
#@stemmed = map( porter("$_"), @words) if $xtremStem;
#@words = @stemmed if $xtremStem;

foreach my $singWord (@words)
{
  push (@singles, $singWord) unless exists $stopHsh{$singWord};
}

### BioPorter dependency
# Only stem words after stop word removal
#@stemmed = map( porter("$_"), @singles) if $stem;
#@singles = @stemmed if $stem;

# start sliding word window co-ordinates.
# I plan to automate this with Ngram generation. Probably through Text::Ngrams or equivalent
my $start = 0;
my $double = 1;
my $triple = 2;
my $four = 3;

my (@doubWd, @tripWd, @fourWd);

  while ($start < ( scalar(@singles) -3) ) {

	my $doubleWord = "$singles[$start] $singles[$double]";
	my $tripleWord = "$singles[$start] $singles[$double] $singles[$triple]";
	my $fourWord = "$singles[$start] $singles[$double] $singles[$triple] $singles[$four]";
	
	push(@doubWd, $doubleWord);
	$termCount{$doubleWord}++;
	
	push(@tripWd, $tripleWord);
	$termCount{$tripleWord}++;
	
	push(@fourWd, $fourWord);
	$termCount{$fourWord}++;
	
	$start++;
	$double++;
	$triple++;
	$four++;
	
}

foreach my $word (@singles)
{
  next if $word =~ /^\d+$|^\w\w$|^\-|\-$|^\S$/;
  $termCount{$word}++;
}

# Remove ngram entries containing duplicated words
my $haRefNoDup = remDup( \%termCount );
my %termNoDup = %$haRefNoDup;
#my %termNoDup = %termCount;

# Remove entries starting with digits
my $haRefNoDig = remDig( \%termNoDup );
my %termNoDig = %$haRefNoDig;

# sort terms by frequency
foreach my $value ( sort { $termNoDig{$b} <=> $termNoDig{$a} } keys %termNoDig)
{
   print $termNoDig{$value}, "\t", $value,  "\n";
 }

### subs ###
sub remDup {
	my $hashRef = shift;
	my %hash = %$hashRef;
	my %wordCnt;
	#my @words;
	foreach my $key (keys %hash) {
		$wordCnt{$_}++ for split(/ /, $key);
		
		foreach my $term (keys %wordCnt) {
		  #print "TERM: ", $key, " WORD: ", $term, " COUNT: ", $wordCnt{$term}, "\n"; 
			if ($wordCnt{$term} > 1) {
				#print $value, "\t", $wordCnt{$value}, "\n";
				delete $hash{$key};
			}
		}
		%wordCnt = ();
	}
	return \%hash;
}


sub remDig {
	my $hashRef = shift;
	my %hash = %$hashRef;
	my @words;
	foreach my $key (keys %hash) 
	{
	  my ($fir, $sec, $thr, $fr) = split(/ /, $key);
	  if ($fir =~ /^\d+|^\-/)
	  {
	    delete $hash{$key};
	  }
	}
	return \%hash;
}
