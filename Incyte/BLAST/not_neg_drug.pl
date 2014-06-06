#!/usr/bin/perl -w

use strict;

my ($id, $hits);
my @drg = ();


while (<>) {
  chomp;
  ($id, $hits) = split(/\t/);
  my @newcat = ();

  @drg = split(/\s/, $hits);
  
  if (/negative_secreted/) {
    for my $i (0 .. $#drg) {
      unless (($drg[$i] =~ /negative_secreted/ )  or 
	      ($drg[$i] =~ /\bsecret/)) {
	push(@newcat, $drg[$i]);
      }
    }
  } else {
    push(@newcat, $hits);
  }

  if (@newcat) {
    print "$id\t", join(" ",  @newcat), "\n";
  }

}
