#!/usr/bin/perl -w

use strict;

my $in_file = $ARGV[0];
my $stopWords = $ARGV[1];

open(STOP, "< $stopWords") || die "cannot open $stopWords: $!\n";
my %stopHsh = ();

while (<STOP>) {
	chomp;
	my $stopStr = $_;
	$stopHsh{$stopStr} = undef;
}
close (STOP);

my $big_string;

{
local $/;   # Set input to "slurp" mode.
open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
$big_string = <IFILE>;
close (IFILE);
}

$big_string =~ s/\n/ /g;
$big_string = lc $big_string;	# convert all to lowercase

$big_string =~ s/pmid//g;
$big_string =~ s/publication types://g;
$big_string =~ s/review//g;
$big_string =~ s/tutorial//g;
$big_string =~ s/\[pubmed - indexed for medline\]//g;

$big_string =~ s/[\{\}\[\]\(\):;!\?,\.\>\<\#\'\\\/\%"\=\*]/ /g; # strip punctuation (\')
$big_string =~ s/&/and/g;
$big_string =~ s/ \w / /g;	# free word characters
$big_string =~ s/ \d+ / /g;	# free digits
$big_string =~ s/\s+/ /g;	# multiple whitespaces

my @words = split(/ /, $big_string);
my $start = 0;
my $double = 1;
my $triple = 2;

my @doubWd_arr = ();
my @tripWd_arr = ();

while ($start < ( scalar(@words) -2) ) {

	my $double_word = "$words[$start] $words[$double]";
	my $triple_word = "$words[$start] $words[$double] $words[$triple]";
	push(@doubWd_arr, $double_word);
	push(@tripWd_arr, $triple_word);
	$start++;
	$double++;
	$triple++;
	
}


# single word frequencies
my $haRef_sing = wordFreq( \@words );
my %singleWordCnt = %$haRef_sing;

# Cut out the stop words from singletones; build new stop word dictionary
my %caughtStopHsh = (); 
foreach my $singleKey (keys %singleWordCnt) {			# trapped single words
	if (exists( $stopHsh{$singleKey} ) ) {		# check against hashed stop keys
		$caughtStopHsh{$singleKey} = undef;		# stop word - add to new hash
		delete $singleWordCnt{$singleKey};			# remove stop word entry from initial hash
	}
}

### We now have: ###
# stopHsh 			- all stop words
# caughtStopHsh		- Caught stop words
# use this reduced list for subsequent matches
# singleWordCnt now has all stop word entries removed

# Double word frequencies
my $haRef_doub = wordFreq( \@doubWd_arr );
my %doubleWordCnt = %$haRef_doub;

# Test H2
#foreach my $Key (keys %doubleWordCnt) {
#	print $Key, "\t", $doubleWordCnt{$Key}, " 1\n";
#}

# Catching stop words in double word list
foreach my $dwordKey (keys %doubleWordCnt) {
	my ($word1, $word2) = split(/ /, $dwordKey);
	if ( (exists( $caughtStopHsh{$word1} ) ) || (exists( $caughtStopHsh{$word2} ) ) ) {
		delete $doubleWordCnt{$dwordKey};
#		print $doubleWordCnt{$dwordKey}, "\t", $dwordKey, "\n";
#		print "$word1 ** $word2\n";
	}
}


# Triple word frequencies
my $haRef_trip = wordFreq( \@tripWd_arr );
my %tripleWordCnt = %$haRef_trip;

# Catching stop words in triple word list
foreach my $twordKey (keys %tripleWordCnt) {
	my ($word1, $word2, $word3) = split(/ /, $twordKey);
	if ( (exists( $caughtStopHsh{$word1} ) ) || (exists( $caughtStopHsh{$word2} ) ) || (exists( $caughtStopHsh{$word3} ) ) ) {
		delete $tripleWordCnt{$twordKey};
#		print "$word1 ** $word2 ** $word3\n";
	}
}

#my %allWordCnt = (%singleWordCnt, %doubleWordCnt, %tripleWordCnt);

#############################################
# Test stop words
#foreach my $stopKey (keys %wordCnt) {
#	print $wordCnt{$stopKey}, "\t", "\n";
#}

# Test doublewords
#foreach my $Key (keys %doubleWordCnt) {
#	print $Key, "\t", $doubleWordCnt{$Key}, " 2\n";
#	print $Key, "\t2\n";
#}

# Test triplewords
#foreach my $Key (keys %tripleWordCnt) {
#	print $Key, "\t", $tripleWordCnt{$Key}, " 2\n";
#	print $Key, "\t2\n";
#}
#############################################


sortFreq( \%tripleWordCnt );
sortFreq( \%doubleWordCnt );
sortFreq( \%singleWordCnt );

# output hash in a descending numeric sort of its values
#foreach my $value ( sort { $allWordCnt{$b} <=> $allWordCnt{$a} } keys %allWordCnt) {
#    print $allWordCnt{$value}, "\t",  $value, "\n";
#}




#### SUBROUTINES ####

# word frequencies subroutine 
sub wordFreq {
	my $arrayRef = shift;
	my %wordCnt = ();
	for my $entry (@$arrayRef) {
		$wordCnt{$entry}++;
	}
	return \%wordCnt;
}

# sort word frequncies
sub sortFreq {
	my $hashRef = shift;
	my %wordCnt =  %$hashRef;
	foreach my $value ( sort { $wordCnt{$b} <=> $wordCnt{$a} } keys %wordCnt) {
		print $wordCnt{$value}, "\t",  $value, "\n";
	}
}
