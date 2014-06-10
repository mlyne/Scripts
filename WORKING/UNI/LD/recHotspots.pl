#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage: recHotspots.pl recombHotspots_file\n";
unless ( $ARGV[0] ) { die $usage }

my $hsFile = $ARGV[0];

# Open the recombination Hotspots file
open(IFILE, "< $hsFile") || die "cannot open $hsFile: $!\n";

my @lines = (<IFILE>);

my $count1 = 0;
my $count2 = 1;

#my $last = $#lines;
my $last = scalar(@lines);
my %dupCoord;

while ($count2 < ($last) ) {

  my ($chrom1, $hapStart1, $hapEnd1, $TgStart1, $TgEnd1) = split(/\t/, $lines[$count1]);
  my ($chrom2, $hapStart2, $hapEnd2, $TgStart2, $TgEnd2) = split(/\t/, $lines[$count2]);
  chomp ($TgEnd1, $TgEnd2);

  $dupCoord{$TgStart1}++;

  my $length = ($TgStart2-$TgEnd1);

  print $length, "\t", $TgEnd1, "\t", $TgStart2, "\n" unless ( exists $dupCoord{$TgStart2} );
#  print "Start: ", $TgEnd1, "\tEnd: ", $TgStart2, "\t", "Len: ", $length, "\n";

  $count1++;
  $count2++;

}
# Close the file we've opened
close(IFILE);

# foreach my $key (%dupCoord) {
# #  print $dupCoord{$key}, "\t", $key, "\n";
# }

