#!/usr/bin/perl -w
use strict;
use warnings;

my $usage = "Usage:ontoGen.pl [-t|-h] pubmed_xml_file stop_words\n

Options:
\t-h\tThis help
\t-t\taccept text file as input
\t-s\tuse word stemming (porter)\n";

unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $text, $stem);

getopts('hts', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $text++;
defined $opts{"s"} and $stem++;

my $in_file = $ARGV[0];
my $termFile = $ARGV[1];

open(TERM_FILE, "< $termFile")  || die "cannot open $termFile: $!";

while (<TERM_FILE>)
{
  chomp;
  (@sTerms) = split(/\n/, $_);
}

close(TERM_FILE);


open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
my $words;

  while (<IFILE>) {
    $words .= $_;
    $words =~ s/^\s+//g;
   }

close (IFILE);
#print $words, "\n";
my $big_string = lc($words);
$big_string =~ s/\n/ /g;
$big_string =~ s/[^[:ascii:]]//g; # strip non-ascii
#$big_string =~ s/[^a-zA-Z\d\s]//g; # strip non letter number
$big_string =~ s/[\{\}\[\]\(\)\:\;\!\?\,\.\>\<\#\'\\\/\%\"\=\*\|\&\@]/ /g; # strip special characters (\')
$big_string =~ s/ - |- | -/ /g;
$big_string =~ s/\&gt|\&lt|\&quot|\&amp//g;	# character codes
$big_string =~ s/\s+/ /g;	# multiple whitespaces

#print $big_string, "\n";

my @words = split(/ /, $big_string);

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
