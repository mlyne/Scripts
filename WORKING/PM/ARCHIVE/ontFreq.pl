#!/usr/bin/perl -w
use strict;
use warnings;

# ./ontologyBuilder.pl file_xml.txt stopList | an_awk_filter >  out_file
# Takes a set of PubMed entries in XML.txt format
# and chops it up into one, two, three, and four word
# combinations. Next it Parses the list using a stopword file

my $in_file = $ARGV[0];
my $stopWords = $ARGV[1];

open(STOPW, "< $stopWords") || die "cannot open $stopWords: $!\n";
my %stopHsh = ();

while (<STOPW>) {
	chomp;
	$stopHsh{$_} = 0;
}
close (STOPW);

open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
my $words;

$/ = undef;

my @entries;
my @addXMLheaders;

while (<IFILE>)
{
	@entries = split(/\n\n/, $_);
}

close (IFILE);

my $xmlHead = shift(@entries);

$/ = "\n";

my @pm;
my $titleCnt; 

foreach my $entry (@entries)
{
  #chomp $entry;
  
  my @lines = split(/\n/, $entry);
  my @titles = grep /ArticleTitle/, @lines;
  my $title = $titles[0];
  $titleCnt++;
  
    $title =~ s/^\s+//g;
    $title =~ s/[\<\/\>]//g;		
    $title =~ s/ArticleTitle//g;
    $words = $title;
    #print $title, "\n***\n\n";
    
    my @abstr = grep /AbstractText/, @lines;
    
    foreach my $abst (@abstr)
    {
      $abst =~ s/^\s+//g;
      $abst =~ s/ Label\=.+?\"\>//g;
      $abst =~ s/[\<\/\>]/ /g;		
      $abst =~ s/AbstractText//g;
      $words .= $abst;
      #print $abst, "\n***\n\n";
   }

    my $bigString = lc($words);	# convert all to lowercase
    $bigString =~ s/\n/ /g;
    $bigString =~ s/[^[:ascii:]]//g; # strip punctuation
    $bigString =~ s/[\{\}\[\]\(\):;!\?,\.\>\<\#\'\\\/\%"\=\*]/ /g; # strip punctuation (\')
    $bigString =~ s/&gt//g;	# character codes
    $bigString =~ s/&lt//g;	# character codes
    $bigString =~ s/&quot//g;	# character codes
    $bigString =~ s/&amp//g;	# character codes
    $bigString =~ s/ -+\w+/ /g;	# words starting with a dash
    $bigString =~ s/ -+\d+/ /g;	# numbers starting with a dash
    $bigString =~ s/ \w / /g;	# free singlet characters
    $bigString =~ s/ \d+ / /g;	# free digits
    $bigString =~ s/\s+/ /g;	# multiple whitespaces
    $bigString =~ s/ \w\w / /g;	# free doublet characters
    $bigString =~ s/ \d+ / /g;	# free multi digets
  
    #print $bigString, "\n***\n";
    push (@pm, $bigString);
}

my $docCnt = scalar(@pm);
my %termCount;

foreach my $doc (@pm)
{
  my @singles;
  my @singWords = split(/ /, $doc);# unless exists $stopHsh{$_};
  foreach my $singWord (@singWords)
  {
  push (@singles, $singWord) unless exists $stopHsh{$singWord};
  $termCount{$singWord}++ unless exists $stopHsh{$singWord};
  }

  my $start = 0;
  my $double = 1;
  my $triple = 2;
  my $four =3;

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
    #print join(" *** ", @singles), "\n";
}

# Remove entries with duplicate words
my $haRefNoDup = remDup( \%termCount );
my %termNoDup = %$haRefNoDup;
#my %termNoDup = %termCount;

my ($totalTermCnt, %docFreqs);

foreach my $key (keys %termNoDup)
{
# print $key, "\t", $termNoDup{$key};
 $totalTermCnt += $termNoDup{$key};
 my $docFreq = grep /\Q$key\E/, @pm;
 $docFreqs{$key} = $docFreq;
}

print "TIT: ", $titleCnt,  " DOCS: ", $docCnt, " TERMS: ", $totalTermCnt, "\n";

 foreach my $value ( sort { $termNoDup{$b} <=> $termNoDup{$a} } keys %termNoDup)
 {
  my ($termFreq, $idf, $tf_idf);
   #sprintf("%.4f", number) - 4 decimal places
   #$dispmax = ($ARGV[2]) ? $ARGV[2] : 10;
   if ($termNoDup{$value})
   {
    $termFreq = sprintf("%.4f", ($termNoDup{$value} / $totalTermCnt) );
    } else {
    $termFreq = "No F Hits";
    }
   
   if ($docFreqs{$value})
   {
    $idf = sprintf("%.4f", (1+ (log ($docCnt / $docFreqs{$value}) ) ) );
    } else {
      $idf = "No Hits";
      }
      
   if ($docFreqs{$value})
   {
    $tf_idf = sprintf("%.4f", ($termFreq * $idf));
    } else {
     $tf_idf = "No Hits"
     }
   
   print "CNT: ", $termNoDup{$value}, "\tDocHits: ", $docFreqs{$value}, "\tTF: ", $termFreq, "\tIDF: ", $idf, "\ttf-idf: ", $tf_idf, "\tTERM: ", $value,  "\n";
#   print $termNoDup{$value}, "\t",  $value, "\n";
 }

#foreach my $value (keys %termNoDup)
#{
  
#}

# # single word frequencies
# my $haRef_sing = wordFreq( \@words );
# my %singleWordCnt = %$haRef_sing;
# 
# # Cut out the stop words from singletones; build new stop word dictionary
# my %caughtStopHsh; 
# foreach my $singleKey (keys %singleWordCnt) {			# trapped single words
# 	if (exists( $stopHsh{$singleKey} ) ) {		# check against hashed stop keys
# 		$caughtStopHsh{$singleKey} = undef;		# stop word - add to new hash
# 		delete $singleWordCnt{$singleKey};			# remove stop word entry from initial hash
# 	}
# }
# 
# ### We now have: ###
# # stopHsh 			- all stop words
# # caughtStopHsh		- Caught stop words
# # use this reduced list for subsequent matches
# # singleWordCnt now has all stop word entries removed
# 
# ############################
# ####### Double Words #######
# # Double word frequencies
# my $haRef_doub = wordFreq( \@doubWd_arr );
# my %doubleWordCnt = %$haRef_doub;
# 
# # Test H2
# #foreach my $Key (keys %doubleWordCnt) {
# #	print $Key, "\t", $doubleWordCnt{$Key}, " 1\n";
# #}
# 
# # Catching stop words in double word list
# foreach my $dwordKey (keys %doubleWordCnt) {
# 	my ($word1, $word2) = split(/ /, $dwordKey);
# 	if ( (exists( $caughtStopHsh{$word1} ) ) || (exists( $caughtStopHsh{$word2} ) ) ) {
# 		delete $doubleWordCnt{$dwordKey};
# #		print $doubleWordCnt{$dwordKey}, "\t", $dwordKey, "\n";
# #		print "$word1 ** $word2\n";
# 	}
# }
# 
# # Remove entries with duplicate words
# $haRef_doub = remDup( \%doubleWordCnt );
# %doubleWordCnt = %$haRef_doub;
# 
# ############################
# ####### Triple Words #######
# # Triple word frequencies
# my $haRef_trip = wordFreq( \@tripWd_arr );
# my %tripleWordCnt = %$haRef_trip;
# 
# # Catching stop words in triple word list
# foreach my $twordKey (keys %tripleWordCnt) {
# 	my ($word1, $word2, $word3) = split(/ /, $twordKey);
# 	if ( (exists( $caughtStopHsh{$word1} ) ) || (exists( $caughtStopHsh{$word2} ) ) || (exists( $caughtStopHsh{$word3} ) ) ) {
# 		delete $tripleWordCnt{$twordKey};
# #		print "$word1 ** $word2 ** $word3\n";
# 	}
# }
# 
# # Remove entries with duplicate words
# $haRef_trip = remDup( \%tripleWordCnt );
# %tripleWordCnt = %$haRef_trip;
# 
# ############################
# ####### Four Words #######
# # Four word frequencies
# my $haRef_four = wordFreq( \@fourWd_arr );
# my %fourWordCnt = %$haRef_four;
# 
# # Catching stop words in triple word list
# foreach my $twordKey (keys %fourWordCnt) {
# 	my ($word1, $word2, $word3, $word4) = split(/ /, $twordKey);
# 	if ( (exists( $caughtStopHsh{$word1} ) ) || (exists( $caughtStopHsh{$word2} ) ) || (exists( $caughtStopHsh{$word3} ) ) || (exists( $caughtStopHsh{$word4} ) ) ) {
# 		delete $fourWordCnt{$twordKey};
# #		print "$word1 ** $word2 ** $word3\n";
# 	}
# }
# 
# # Remove entries with duplicate words
# $haRef_four = remDup( \%fourWordCnt );
# %fourWordCnt = %$haRef_four;
# 
# sortFreq( \%fourWordCnt );
# sortFreq( \%tripleWordCnt );
# sortFreq( \%doubleWordCnt );
# sortFreq( \%singleWordCnt );
# 
# #### SUBROUTINES ####
# 
# # word frequencies subroutine 
# sub wordFreq {
# 	my $arrayRef = shift;
# 	my %wordCnt = ();
# 	for my $entry (@$arrayRef) {
# 		$wordCnt{$entry}++;
# 	}
# 	return \%wordCnt;
# }
# 
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
# 
# # sort word frequncies
# sub sortFreq {
# 	my $hashRef = shift;
# 	my %wordCnt =  %$hashRef;
# 	foreach my $value ( sort { $wordCnt{$b} <=> $wordCnt{$a} } keys %wordCnt) {
# 		print $wordCnt{$value}, "\t",  $value, "\n";
# 	}
# }
