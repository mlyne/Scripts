#!/usr/bin/perl -w
#use strict;

#reference size = $ARGV[0]
#reference positives = $ARGV[1];
#sample size = $ARGV[2]
#sample positives = $ARGV[3];

print  &uppertail_hypergeometric($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3]);

sub uppertail_hypergeometric {
    my ($N, $m, $n, $k) = @_;
    my $not_m = $N - $m;

	if ($m < $n ){$i_max = $m;}else { $i_max = $n;} 
    
    for($i=$i_max; $i >= $k; $i--) 
    {
		#print "$m $not_m $n $i\n";
        $uppertail_hypergeom3 += &hypergeom($m,$not_m,$n,$i);
    }

    return $uppertail_hypergeom3;
}

sub logfact {
   return gammln(shift(@_) + 1.0);
}

sub hypergeom {
   my ($n, $m, $N, $i) = @_;

   my $loghyp1 = logfact($m)+logfact($n)+logfact($N)+logfact($m+$n-$N);
   my $loghyp2 = logfact($i)+logfact($n-$i)+logfact($m+$i-$N)+logfact($N-$i)+logfact($m+$n);
   return exp($loghyp1 - $loghyp2);
}

sub gammln {
  my $xx = shift;
  my @cof = (76.18009172947146, -86.50532032941677,
             24.01409824083091, -1.231739572450155,
             0.12086509738661e-2, -0.5395239384953e-5);
  my $y = my $x = $xx;
  my $tmp = $x + 5.5;
  $tmp -= ($x + .5) * log($tmp);
  my $ser = 1.000000000190015;
  for my $j (0..5) {
     $ser += $cof[$j]/++$y;
  }
  -$tmp + log(2.5066282746310005*$ser/$x);
}


