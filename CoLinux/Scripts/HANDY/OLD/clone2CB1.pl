#!/usr/bin/perl -w
#
#
#

use strict;
use Getopt::Std;
use IO::File;

my $usage = "Usage:clone2CB1.pl pattern_file table_file\n";

my (%opts);

getopts('h', \%opts);
defined $opts{"h"} and die $usage;

my $arg = shift(@ARGV);
my @cloneids = ();

if ( -f "$arg" ) {
  my $fh = new IO::File("<$arg") || die "Could not open $arg : $!\n";
  while (<$fh>) {
    chomp;
    push @cloneids, $_;
  }
  $fh->close;
} else {
  push @cloneids, $arg;
}

my ($cb, $line, $rest);

while (defined($line = <>)) {
  ($cb, $rest) = split("\t", $line);
  foreach (@cloneids) {
    if ($rest =~ /\b\Q$_\E\b/) {
      print "$_\t$cb\n";
    }
  }

}
