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

for my $entry (@matrix)
{
  chomp $entry;
  

  my @array = split("\t", $entry);
  my $drug = shift(@array);
#  my $allHits = shift(@array); # used with drg vs. all J. hits 
  my $count = "0";
  for my $val (@array) { $count += "$val" }

  my $average = $count / scalar(@array);
  
  next unless ($average);
  my @calc = ();
  if ($average)
  {
  	@calc = map($_ / $average, @array);
  }
  
  print $drug, "\t";
  
# used with drg vs. all J. hits 
#  print $allHits, "\t", $count, "\t", scalar(@array), "\t", $average, "\n";
#  my @calc = map($_ / $allHits, @array);

  print join("\t", @calc), "\n";
}
