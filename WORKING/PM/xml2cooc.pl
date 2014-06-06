#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use utf8;
#use Text::Unidecode;
#use XML::Twig::XPath;

my $usage = "Usage:xml2Cooc.pl pubmed_xml t1_file t2_file OUT_FILE

t1 & t2 files are plain text term files - one term per line
eg. glaucoma

Options:
\t-h\tThis help
\t-a\tPrint Authorsl\n
";

unless ( $ARGV[3] ) { die $usage }

### command line options ###
my (%opts, $optAuth);

getopts('ha', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"a"} and $optAuth++;

# Take input from the command line

my $xmlFile = $ARGV[0];
my $term1_file = $ARGV[1];
my $term2_file = $ARGV[2];
my $out_file = $ARGV[3];


open(IFILE, "< $xmlFile") || die "cannot open $xmlFile: $!\n";
open(T1FILE, "< $term1_file") || die "cannot open $term1_file: $!\n";
open(T2FILE, "< $term2_file") || die "cannot open $term2_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

my (@entries);

{
  local $/ = undef;

  while (<IFILE>)
  {
#    $_ =~ s/\<PubmedArticleSet\>\n\<PubmedArticle\>/\<PubmedArticleSet\>\n\n\n\<PubmedArticle\>/;
#    @entries = split(/\n\n/, $_);
    @entries = split('</PubmedArticle>', $_);
  }
}

close(IFILE);

my (@termset1, @termset2);

# Read queries into an array
chomp (@termset1 = <T1FILE>); 
chomp (@termset2 = <T2FILE>); 

close(T1FILE);
close(T2FILE);

my %freqHash = ();

foreach my $entry (@entries)
{
  my ($words, $big_string);
  my @lines = split(/\n/, $entry);

  #print join('\n', @abst);
  
  foreach my $line (@lines) {
#    print "LINE: ", $line;
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
	$abst =~ s/ABSTRACT//g;
	$abst =~ s/[\<\/\>]/ /g;		
	$abst =~ s/\<\/*AbstractText.+?\>//g;
	$abst =~ s/ \d+\. //g;
	$abst =~ s/\d+,\d+//g;
	$words .= $abst;
  #	print $abst, "\n***\n\n";
    }
   }
    
  next unless $words;
  $big_string = lc($words);
  $big_string =~ s/\n/ /g;
  $big_string =~ s/[^[:ascii:]]//g; # strip non-ascii
  #$big_string =~ s/[^a-zA-Z\d\s]//g; # strip non letter number
  $big_string =~ s/[\{\}\[\]\(\)\:\;\!\?\,\.\>\<\#\'\\\/\%\"\=\*\|\&\@]/ /g; # strip special characters (\')
  $big_string =~ s/ - |- | -/ /g;
  $big_string =~ s/\&gt|\&lt|\&quot|\&amp//g;	# character codes
  $big_string =~ s/\s+/ /g;	# multiple whitespaces

#  print $big_string, "\n-------------- --------------\n";

  foreach my $term1 (@termset1) {
#    my ($t1Hit, $t2Hit);
    my $t1Hit = grep /\Q$term1\E/, $big_string;
  
    foreach my $term2 (@termset2) {
      my $t2Hit = grep /\Q$term2\E/, $big_string;
       my $termString = "$term1\t$term2";
       
       $freqHash{$termString}++ if ($t1Hit && $t2Hit);
      
#      print "$term1 $term2\n", if ($t1Hit && $t2Hit);
#      print "HIT: $big_string\n", if ($t1Hit && $t2Hit);
#  my $termHit = grep /AbstractText/, @lines;
    }
  }
}

foreach my $key (sort { $freqHash {$b} <=> $freqHash {$a} } keys %freqHash) 
{
     print OUT_FILE $key, "\t", $freqHash{$key},"\n";
}

close(OUT_FILE);
