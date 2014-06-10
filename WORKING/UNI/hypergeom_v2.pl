#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Math::Pari qw/binomial pari2num/;

# my $val = hypergeometric(300,40,700,100); 
my $val = hypergeometric(40,6,53,15);

##input ($M,$p,$F,$n)  --> M=5, p=3, F=53, n=5
# where # M=M, p=k, F=N, n=n and ...
# n = the number of objects in your list
# F,N = the number of objects in the reference population
# p,k = the number of objects annotated with this item in your list
# M = the number of objects annotated with item in the reference population 

# ( 300, 700, 100, 40 );
# (5,3,53,5);

print "Hyper = $val\n";

sub hypergeometric {

    my ($M,$p,$F,$n) = @_;
    return unless $n>0 && $n == int($n) && $p > 0 && $p == int($p) &&  $M > 0;
#    return unless $M <= $n+$p;
    return 0 unless $p <= $M && $p == int($p);

    return pari2num((binomial($M,$p) * binomial($F-$M, $n-$p) / binomial($F,$n))); 

}
