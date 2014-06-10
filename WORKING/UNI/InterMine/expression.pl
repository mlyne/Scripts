#!/usr/bin/perl -w

use strict;
use warnings;
#use LWP;

## Extracts expression data from Nicolas et al., 2012 - Table S4

use Statistics::Basic::StdDev;
use Statistics::Basic::Mean;
use Statistics::ANOVA;

my $file = $ARGV[0];
#my $out_file = $ARGV[1];

open(FILE, "< $file") || die "cannot open $file: $!\n";
#open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

chomp (my @matrix = <FILE>);
#my $info = shift(@matrix);
my $headers = shift(@matrix); # extract headers
my ($name_h, $locus_tag_h, $startV3_h, $endV3_h, $startV2_h, $endV2_h, $strand_h, $keeptot_h, $keeptrim_h, $id260210_h, $origId_h, $classif_h, $data_h) = split("\t", $headers, 13);

# split expression data into new array
my @expHead = split("\t", $data_h);

# how many columns
my $elCnt = $#expHead;

# going to be used to track data co-ordinates
my @expPos;

# going to be used to track seen items and column order
my (%seen, %dataOrder);

my $posn = 0;
my $count = 1;

#print $count, "\n";

foreach my $head (@expHead) {
  my ($exp, $rep, $hybID) = split("_", $head); # exper, replicate#, hybID (don't need)

  if ($exp =~ m"/t") { 
    $posn++; # increment array posn
    next; # get rid of technical replicates
  }
  
  $dataOrder{$exp} = $count; # start track of column order
  $count++ unless exists ( $seen{$exp} );
  push ( @{ $seen{$exp} }, $posn );
#  print "$exp, $rep, $posn, $count\n";
  $posn++; # incr. array posn
  
}

print $name_h, "\t", $locus_tag_h; # print headers

for my $key ( sort { $dataOrder{$a} <=> $dataOrder{$b} } keys %dataOrder ) {
  print "\t", $key; # print exper names

}

print "\trowAvg\n";

#my (@newData, @rowVals);
for my $entry (@matrix)
{
  chomp $entry;
  my ($name, $locus_tag, $startV3, $endV3, $startV2, $endV2, $strand, $keeptot, $keeptrim, $id260210, $origId, $classif, $data) = split("\t", $entry, 13);
  my @exprVal = split("\t", $data);

  print $name, "\t", $locus_tag;

  my (@newData, @CVs, @rowVals, @pVals);
  for my $key ( sort { $dataOrder{$a} <=> $dataOrder{$b} } keys %dataOrder ) {
    
    my ($currVal, @slice);
    for my $val (@{ $seen{$key} } ) {
      $currVal = $exprVal[$val];
      push(@slice, $currVal);
      push(@rowVals, $currVal);
    }

    my ($mean, $sd, $cv, $reps) = &computeStats( \@slice );
    $mean = ($mean) ? $mean : $currVal;
    $cv = "NA" if ($reps < 2);
    push (@newData, $mean);
    push (@CVs, $cv);

#    print "\t$mean, $sd, $cv, $reps\n";

### ANOVA
#     my $d2 = "globalMean";
#     my $pval = &anova ($key, $d2, \@slice, \@rowVals);
#     push(@pVals, $pval);

  } 
#  my $roundPvals = &stround(3, \@pVals);

  my ($row_mean, $row_sd, $row_cv, $row_reps) = &computeStats( \@rowVals );
  
  my @diffExpr = map { $_ - $row_mean } @newData;
  my $roundExpr = &stround(3, \@diffExpr);
  my $roundCV = &stround(3, \@CVs);
#  print "\t$row_mean, $row_sd, $row_cv, $row_reps\n";

  for (my $i = 0; $i < @diffExpr; $i++) {
#    print  "\t", @{ $roundExpr }[$i], " :", @{ $roundPvals }[$i];
    print  "\t", @{ $roundExpr }[$i], " :", @{ $roundCV }[$i];
  }

#  print "\t", join("\t", @{ $roundExpr } ), "\t", "*** $row_mean ***", "\n";
#  print "\t", join("\t", @pVals), "\tnoVal\n";
  print "\n";
}


sub computeStats {

  my ($data) = @_;
  my $mean = new Statistics::Basic::Mean($data)->query;
  my $sd = ($mean) ? new Statistics::Basic::StdDev($data)->query : "NA";
  my $cv = ($mean) ? $sd / $mean : "NA";
#  print "\t$mean, $sd, $cv, ", scalar(@$data), "\n";
  return ( $mean, $sd, $cv, scalar(@$data) );
}

sub anova {
  my ($dataID1, $dataID2, $dataRef1, $dataRef2) = @_;

  my $aov = Statistics::ANOVA->new();

  $aov->load( "$dataID1", @{ $dataRef1 } );
  $aov->add( "$dataID2", @{ $dataRef2 } );
#     $aov->add( "$dataID2", \@{$datasets{$dataset}[1]} );

  my $str = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
#  $aov->anova(independent => 1, parametric => 1)->dump(title => 'Indep. groups parametric ANOVA', eta_squared => 1, omega_squared => 1);
#  $aov->compare(independent => 1, parametric => 1, flag => 1, alpha => .05, dump => 1); # Indep. obs. F- (or t-)tests
  my $pval = $str->{_stat}->{p_value};
}

sub stround {
    my( $places, $arrRef ) = @_;
    
    my @arrRound;
    foreach my $n ( @{ $arrRef } ) {
      if ($n =~ /\d/) {
	my $sign = ($n < 0) ? '-' : '';
	my $abs = abs $n;
	my $val = $sign . substr( $abs + ( '0.' . '0' x $places . '5' ), 0, $places + length(int($abs)) + 1 );
	push(@arrRound, $val);
      } else {
	my $val = $n;
	push(@arrRound, $val);
      }
    }
    return (\@arrRound);
}