#!/usr/bin/perl -w
use strict;
use warnings;

my $usage = "Usage:subtrTerms.pl termFile coocTermFile\n";

unless ( $ARGV[1] ) { die $usage }

my $termFile = $ARGV[0];
my $coocFiles = $ARGV[1];

open(TERM_FILE, "< $termFile") || die "cannot open $termFile: $!\n";

my %termHash = ();

while (<TERM_FILE>) {
  chomp;
  my ($count, $term) = split /\t/, $_;
  $termHash{$term}++;
}
close (TERM_FILE);

open(COOC_FILE, "< $coocFiles") || die "cannot open $coocFiles: $!\n";
my @words;
my %coocHash = ();

while (<COOC_FILE>) {
  chomp;
  my ($count, $coTerm1, $coTerm2) = split /\t/, $_;
  next if (( exists $termHash{$coTerm1} ) || ( exists $termHash{$coTerm2} ));
  print $count, "\t", $coTerm1, "\t", $coTerm2, "\n";
}
close (COOC_FILE);

# foreach my $key ( keys %termHash ) 
# {
#   if ( exists $coocHash{$key} )
#   {
#     delete $coocHash{$key};
#   }
# }
# 
# foreach my $key (sort { $coocHash {$b} <=> $coocHash {$a}} keys %$coocHash) 
# {
#   print $key,"\t", "FOUND","\n";
# }
# 
# foreach my $key (sort { $coocHash {$b} <=> $coocHash {$a}} keys %$coocHash) 
# {
#   print $key,"\t", "FOUND","\n";
# }
# 
# delete $coocHash{$key};
