#!/usr/local/bin/perl -w 
#
#
#

while (<>) {
  chomp;
  $line = $_;
  
  $entry = `efetch $line`;

  print "$entry//\n";
}
