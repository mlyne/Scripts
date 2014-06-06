#!/usr/bin/perl -w

use strict;

my $file = $ARGV[0];
open(FILE, "< $file") || die "cannot open $file: $!\n";

chomp (my @matrix = <FILE>);
my $headers = shift(@matrix);
my @headers = split("\t", $headers);

#splice(@headers, 0, 2); # used with drg vs. all J. hits 
splice(@headers, 0, 1);

for my $header (@headers)
{
	$header =~ s/\"//g;
	$header =~ s/\s/ /g;
}

print "Drug\t";
print join("\t", @headers);
print "\n";

for my $entry (@matrix)
{
  chomp $entry;
  

  my @array = split("\t", $entry);
  my $drug = shift(@array);
  print $drug;
  
  for my $val (@array)
  {
  	my $scale = "0";
  	if ($val >= 500) {$val = "500";}
#  	if ($val >= 50) {$scale = "50";}
#  	elsif ( ($val >= 30) && ($val < 40) ) {$scale = "4";}
#  	elsif ( ($val >= 20) && ($val < 30) ) {$scale = "3";}
#  	elsif ( ($val >= 10) && ($val < 20) ) {$scale = "2";}
#  	elsif ( ($val > 0) && ($val < 10) ) {$scale = "1";}
#  	else {$scale = "0";}
  	
  	print "\t", $val;
  }
  print "\n";

#  my @calc = map($_ / $allHits, @array);

#  print join("\t", @calc), "\n";
}
