#!/usr/bin/perl -w


use strict;

my $hrShit = {};
my @f;
my $arVal;

while (<>) {
  @f = split(/\t/);
  if (exists($hrShit->{$f[0]}->{$f[2]})) {
    $arVal = $hrShit->{$f[0]}->{$f[2]};
  } else {
    $hrShit->{$f[0]}->{$f[2]} = [ $f[2] ];
  }
}

my ($clone_id, $drug_cat, $hrClone);

while (($clone_id, $hrClone) = each %$hrShit) {
  while (($drug_cat, $arVal) = each %$hrClone) {
#    print  "$clone_id\t", $arVal->[0];
    print "$clone_id\t$drug_cat";
  }
}


