#!/usr/local/bin/perl -w
#
#
#

$usage = "Usage:RT-Reformat.pl file_to_reformat";

unless ( $ARGV[0] ) { die $usage }

READ_LOOP: while (<>) 
{

  if (m/^([a-zA-Z0-9_]+)\t/g){
    $id = $1;
#    print "$id\n";
  }

  if (m/Adipose-white\t(\d+\.\d+)/)
  {
     $brain = $1;
#     print "$brain\n";
   }

  if (m/Bladder\t(\d+\.\d+)/)
  {
    $bladder = $1;
#    print "$bladder\n";
    push @row, [$id, $brain, $bladder];

  }

next READ_LOOP;

}

for $i (0..$#row)
{
#  print @{$row[$i]}, "\n";
  print join("\t", @{$row[$i]});
  print "\n";
}
