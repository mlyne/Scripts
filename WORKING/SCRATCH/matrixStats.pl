#!/usr/bin/perl

use strict;
use warnings;

## Input three tab sep files
# go_file = GOtermID, GOtermName, parent_GOtermID, parent_GOtermName
# func_file = locusID, ... otherstuf ..., GO terms of format:
# GO:number:namespace:term name
# diffExpr_file = up or down regulated gene sets 
# format slightly different to func_file but treated the same
# locusID, ... otherstuf ..., GO terms

my $go_file = $ARGV[0];
my $func_file = $ARGV[1];
my $diffExpr_file = $ARGV[2];

my (%GOtree, %GOdetails, %GOcountAll);
# GOtree = keep track of terms & parents with hash of hashes
# GOdetails = GO IDs with term names
# %GOcountAll = freq of a given GO term

my ($refSize, $sampSize);

open GO_IN, "$go_file" or die "can't open file";

while (<GO_IN>) {
  chomp $_;
  my ($GOtermID, $GOtermName, $GOparID, $GOparName) = split( /\t/, $_ );
  $GOdetails{$GOtermID} = $GOtermName; # store GO IDs with term names
  $GOdetails{$GOparID} = $GOparName; # store parent GO IDs with names

# make a hash of hashes. Each term has a collection of parents
# terms IDs are accessed: foreach my $term (keys %GOtree) {
# parent terms are accessed: foreach my $par (keys %{ $GOtree{$term} }) {
# foreach my $term (keys %GOtree) {
#   foreach my $par (keys %{ $GOtree{$term} }) {
# #    print "TERM: ", $term, "\tPAR: ", $par, "\n";
#   }
# }

  $GOtree{$GOtermID}{$GOparID}++; # hash{term} => {parent} => 1;

}
close GO_IN; # close GOterm2parents file


open FUNC_IN, "$func_file" or die "can't open file";
#open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

while (<FUNC_IN>) {
  chomp $_;
  next unless $_ =~ /ZDB-GENE/; # subset with ZFIN IDs - remove for full analysis
  next if $_ =~ /NO Gene Ontology/; # discard results with no GO terms
  
  my @split = split( /\t/, $_ ); # split the file to an array
  my $locus = $split[0]; # use array addresses to access values eg. Locus ID

  my @GOlist = split( /\; /, $split[5] ); # split the GO terms to an array

  foreach my $GOterm (@GOlist) {
    my ($g, $idNo, $namespace, $name) = split( /\:/, $GOterm ); # split each GO hit
    next unless $namespace =~ /P/; # comment to analyse all namespaces
      # P = biological_process, C = cellular_component, F = molecular_function
    $refSize++; # count how many reference results have GO terms

    my $testTerm = "$g:$idNo"; # join up the GO & number parts

    if (exists $GOtree{$testTerm} ) {
      $GOcountAll{$testTerm}++; # count the term
#      print $testTerm, "\t";

      foreach my $par (keys %{ $GOtree{$testTerm} }) {
	$GOcountAll{$par}++; # count the parent terms
#	print $par, "\t";
      }
    }
#      print "\n";
  }
}

close FUNC_IN;

open DIFF_IN, "$diffExpr_file" or die "can't open file";

my (%GOcountDiff); # set up a count for sample GO term freq

while (<DIFF_IN>) {
  chomp $_;
  next unless $_ =~ /ZDB-GENE/; # remove for full analysis
  next if $_ =~ /NO Gene Ontology/;

  my @split = split( /\t/, $_ );
  my $locus = $split[0];

  my @GOlist = split( /\; /, $split[7] );

  foreach my $GOterm (@GOlist) {
    my ($g, $idNo, $namespace, $name) = split( /\:/, $GOterm );
    next unless $namespace =~ /P/; # comment to analyse all namespaces
    # P = biological_process, C = cellular_component, F = molecular_function
    $sampSize++; # count how many sample results have GO terms

    my $testTerm = "$g:$idNo";

    if (exists $GOtree{$testTerm} ) {
      $GOcountDiff{$testTerm}++; # count the sample term 
#      print $testTerm, "\t";

      foreach my $par (keys %{ $GOtree{$testTerm} }) {
	$GOcountDiff{$par}++; # count the sample parent terms
#	print $par, "\t";
      }
    }
#      print "\n";

  }
}

close DIFF_IN; # close the sample file

#print "REF: ", $refSize, "\tSAMP: ", $sampSize, "\n";

## if we want to get a sorted list of count vs GO terms
#foreach my $termTotal  (sort { $GOcountAll {$b} <=> $GOcountAll {$a}} keys %GOcountAll ){
#  print "$GOcountAll{$termTotal}\t$termTotal\n";
#}

print "BonfCorrect\tun-adj p-val\tGOid\tGOname\trefSize refPos sampSize sampPos\n"; # headings

foreach my $diffTerm  (keys %GOcountDiff ){
  if (exists $GOcountAll{$diffTerm} ) {
    my $refPos = $GOcountAll{$diffTerm}; # get the count for reference set positives
    my $samPos = $GOcountDiff{$diffTerm}; # get the count for sample set positives

# Here's the call to Adrian's hypergeometric function
# In this order, we give it:
#reference size = $refSize;
#reference positives = $refPos;
#sample size = $sampSize;
#sample positives = $samPos;

    my $pval = &uppertail_hypergeometric($refSize,$refPos,$sampSize,$samPos);
    my $bonf = $pval * $sampSize;

    print $bonf, "\t", $pval, "\t", $diffTerm, "\t", $GOdetails{$diffTerm}, "\t" .
    "$refSize $refPos $sampSize $samPos" .
    "\n";
  }
#  print "$GOcountDiff{$termTotal}\t$termTotal\n";
}

### Hypergeometric Distribution sub
sub uppertail_hypergeometric {

# In this order, we give it:
#reference size = $refSize = $N
#reference positives = $refPos = $m
#sample size = $sampSize = $n
#sample positives = $samPos = $k

    my ($N, $m, $n, $k) = @_;
    my $not_m = $N - $m;
    my ($i, $i_max, $uppertail_hypergeom3);

	if ($m < $n ){$i_max = $m;} else { $i_max = $n;} 
    
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


