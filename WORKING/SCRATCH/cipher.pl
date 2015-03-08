#!/usr/bin/perl

use strict;
use warnings;

use feature ':5.12';

my ($ciph, $string) = @ARGV;

#my $ciph = 3;
#my $string = "the quick brown fox";

my (%ln, %nl, %code);

@ln{("a".."z")} = (1..26); 
@nl{(1..26)} =("a".."z");
$ln{" "} = (0);
$nl{(0)} = (" ");

my @message = split("", $string);

for my $letter (@message) {
  my $secret;
  
  if ($letter =~ / /) {
    $secret = 0;
  }
  elsif ( $ln{$letter} + $ciph <= 26) {
    $secret = ($ln{$letter} + $ciph);
  } else {
   $secret = (($ln{$letter} + $ciph) - 26);
  }
  print $nl{$secret};
}
say "";