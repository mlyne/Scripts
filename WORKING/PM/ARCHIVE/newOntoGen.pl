#!/usr/bin/perl -w
use strict;
use warnings;

# ./ontologyBuilder.pl file_xml.txt stopList | an_awk_filter >  out_file
# Takes a set of PubMed entries in XML.txt format
# and chops it up into one, two, three, and four word
# combinations. Next it Parses the list using a stopword file

my $in_file = $ARGV[0];
my $stopWords = $ARGV[1];

open(STOP, "< $stopWords") || die "cannot open $stopWords: $!\n";
my %stopHsh = ();

while (<STOP>) {
	chomp;
#	my $stopStr = $_;
	$stopHsh{$_}++;
}
close (STOP);

open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
my $words;

while (<IFILE>) {
	chomp;
	my $line = $_;
	if ($line =~ (/ArticleTitle/) ) {
		my $title = $line;
		$title =~ s/^\s+//g;
		$title =~ s/[\<\/\>]//g;		
		$title =~ s/ArticleTitle//g;
		$words .= $title;
#		print $title, "\n***\n\n";
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
#		print $abst, "\n***\n\n";
	}
}
close (IFILE);
#print $words, "\n";
my $big_string = lc($words);
$big_string =~ s/\n/ /g;
$big_string =~ s/\s+/ /g;	# multiple whitespaces
$big_string =~ s/[^[:ascii:]]//g; # strip punctuation
$big_string =~ s/[\{\}\[\]\(\):;!\?,\.\>\<\#\'\\\/\%"\=\*]/ /g; # strip punctuation (\')
$big_string =~ s/&gt//g;	# character codes
$big_string =~ s/&lt//g;	# character codes
$big_string =~ s/&quot//g;	# character codes
$big_string =~ s/&amp//g;	# character codes
#$big_string =~ s/\b\-\w+\b//g;	# words starting with a dash
#$big_string =~ s/\b\-\d+\b//g;	# numbers starting with a dash
#$big_string =~ s/\b\w\b//g;	# free singlet characters
#$big_string =~ s/ \d+ / /g;	# free digits
#$big_string =~ s/\b\w\w\b//g;	# free doublet characters

#print $big_string, "\n";

my @words = split(/\s+/, $big_string);

my (@singles, %termCount);

foreach my $singWord (@words)
{
  #next if ($singWord =~ /^\d+$/);
  push (@singles, $singWord) unless exists $stopHsh{$singWord};
#  $termCount{$singWord}++ unless exists $stopHsh{$singWord};
}

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
  next if $word =~ /^\d+$|^\w\w$|^\-|\-$/;
  $termCount{$word}++;
}

# Remove entries with duplicate words
my $haRefNoDup = remDup( \%termCount );
my %termNoDup = %$haRefNoDup;
#my %termNoDup = %termCount;

# Remove entries starting with digits
my $haRefNoDig = remDig( \%termNoDup );
my %termNoDig = %$haRefNoDig;

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
