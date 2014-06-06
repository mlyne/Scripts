#!/usr/local/bin/perl -w
#
# loops through an array four elements
# at a time :-) Try with farm_test

while (<>) {
  @array = split(/,/, $_);
}

$i=0;
$j=3;

while ($j < $#array) {
  @array2 =();
  @array2 = @array[$i..$j];
  $i = $j + 1;
  $j = $j + 4;

  print join(",", @array2), "\n";
}
