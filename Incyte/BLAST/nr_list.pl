#!/usr/bin/perl -w

use Getopt::Std;
use strict;

my (%opts, $drg);

getopts('d', \%opts);
defined $opts{"d"} and $drg++;

my $hrShit = {};
my $key;
my @f;
my $line;
my $arVal;

while (<>) {
  @f = split(/\t/, $_, 6);
  $f[5] =~ s/\..+$//g if $drg;
  $line = join("\t", @f);

  if (exists($hrShit->{$f[3]}->{$f[5]})) {
    $arVal = $hrShit->{$f[3]}->{$f[5]};
    if ($f[0] > $arVal->[0]) {
      $hrShit->{$f[3]}->{$f[5]} = [ $f[0], $line ];
    }
  } else {
    $hrShit->{$f[3]}->{$f[5]} = [ $f[0], $line ];
  }
}

my ($clone_id, $drug_cat, $hrClone);

while (($clone_id, $hrClone) = each %$hrShit) {
  while (($drug_cat, $arVal) = each %$hrClone) {
    print $arVal->[1];
  }
}
