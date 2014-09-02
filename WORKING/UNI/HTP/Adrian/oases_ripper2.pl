#!/usr/bin/perl
use warnings;

$sequence_file = $ARGV[0];
$loci_file = $ARGV[1];

open IN, "$sequence_file" or die "can't open file";
while (<IN>) {
   chomp $_;
   if ( $_ =~ m/^>/ ) {
       if ($current_seq) {
           $sequences_index{$current_header} = "$current_seq";
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
close IN;

foreach $header (keys %sequences_index){

$header =~ m/^>(Locus_\d+)_/;
$locus = $1;
$current_length = length $sequences_index{$header};

if ($max_length{$locus}){ 

if ($max_length{$locus} < $current_length){
$max_length{$locus} = $current_length;
$header_longest{$locus} = $header;
$seq_longest{$locus} = $sequences_index{$header};
}


} else {$max_length{$locus} = $current_length;
$header_longest{$locus} = $header;
$seq_longest{$locus} = $sequences_index{$header};

}
}


open IN, "$loci_file" or die "can't open file";
while (<IN>) {
chomp $_;
$loci{$_} = 1;
}

foreach $locus (keys %loci){
print "$header_longest{$locus}\n$seq_longest{$locus}\n";
}


#}
#close IN;
