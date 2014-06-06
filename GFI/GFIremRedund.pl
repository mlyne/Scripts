#!/usr/bin/perl -w

use strict;

my $hrHit = {};
my @f;
my $line;
my $arVal;

while (<>) {
  @f = split(/\t/, $_);
  $line = join("\t", @f);

  if (exists($hrHit->{$f[0]}->{$f[1]}->{$f[2]})) {
  	next;
  } else {
    $hrHit->{$f[0]}->{$f[1]}->{$f[2]} = "$line";
  }
}

my ($site, $score, $desc, $hrScore, $hrDesc);

while (($site, $hrScore) = each %$hrHit) {
  while (($score, $hrDesc) = each %$hrScore) {
  	while (($desc, $arVal) = each %$hrDesc) {
    	print $arVal;
	}
  }
}
