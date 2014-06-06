#!/usr/bin/perl
use warnings;

$sequence_file = $ARGV[0];
$min_contig_length = $ARGV[1];

open IN, "$sequence_file" or die "can't open file";
while (<IN>) {
   chomp $_;
   if ( $_ =~ m/^>/ ) {
       if ($current_seq) {
           $sequences_index{$current_header} = "$current_seq";
		$sequence_length{$current_header} = length $current_seq;
	$current_seq = undef;
       }
       $current_header = $_;
      


   }
   else {
       $_ = uc($_);
       $current_seq .= "$_";
   }
}

 $sequences_index{$current_header} = "$current_seq";
$sequence_length{$current_header} = length $current_seq;
close IN;




foreach $header (reverse sort length_sort keys %sequence_length){

if ($sequence_length{$header} >= $min_contig_length){
print "$header\n$sequences_index{$header}\n";
}
}

sub length_sort {
  return -1 if ($sequence_length{$a} < $sequence_length{$b});
  return 0 if $sequence_length{$a} == $sequence_length{$b};
  return 1 if $sequence_length{$a} > $sequence_length{$b};
}
