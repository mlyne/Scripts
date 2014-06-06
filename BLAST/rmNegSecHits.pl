#!/software/arch/bin/perl -w
#
#
#

use strict;

my $hrShit = {};
my @f;

while (<>) {
  @f = split(/\t/);
  $hrShit->{$f[3]}->{$f[5]} = [ $_ ];
}

my ($clone_id, $drug_cat, $hrClone, $arVal);
my @neg;

while (($clone_id, $hrClone) = each %$hrShit) {
  while (($drug_cat, $arVal) = each %$hrClone) {
    if ($drug_cat =~ /negative/) {
      push @neg, $clone_id;
    }
  }
}

my ($cat);

for (@neg) {
  while (($cat, $arVal) = each %{$hrShit->{$_}}) {
    if ($cat =~ /secret/) {
      delete $hrShit->{$_}->{$cat};
    }
  }
}

while (($clone_id, $hrClone) = each %$hrShit) {
  while (($drug_cat, $arVal) = each %$hrClone) {
    print $arVal->[0];
  }
}
