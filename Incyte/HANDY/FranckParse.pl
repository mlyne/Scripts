#!/software/arch/bin/perl -w 
#
#
#

while (<>) {
  chomp;
  ($contig, $kid, $qes, $mcu, $zgn) = split("\t", $_);
  
  $kid = count($kid);
  $qes = count($qes);
  $mcu = count($mcu);
  $zgn = count($zgn);

  print "$contig, $kid, $qes, $mcu, $zgn\n";
}

sub count {
  $var = shift;
  if ($var) {
    split(",", $var);
    $var = $_[-1];
  }
}
