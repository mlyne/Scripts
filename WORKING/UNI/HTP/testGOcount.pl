#!/usr/bin/perl

use strict;
use warnings;

my $usage = "Usage: parseGO.pl GO_term_file processed_blast_file diffExpr_blast_file
Version 2.0
## Input three tab sep files
# go_file: produced from parent_children relations from flyMine
# Format - tab separated: GOtermID, GOtermName, parent_GOtermID, parent_GOtermName 

# func_file: locusID, [... otherstuf ...], GO terms of format:
# GO:number:namespace:term name

# diffExpr_blast_file - from up or down regulated gene sets 
# TAB sep format slightly different to func_file but treated the same
# locusID, [... otherstuf ...], GO terms, etc
\n";

my $go_file = $ARGV[0];
my $func_file = $ARGV[1];

unless ( $ARGV[1] ) { die $usage }

our (%GOtree, %GOdetails, %GOcountAll);
# GOtree = keep track of terms & parents with hash of hashes
# GOdetails = GO IDs with term names
# %GOcountAll = freq of a given GO term

our ($refSize, $sampSize);

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
#  next unless $_ =~ /ZDB-GENE/; # subset with ZFIN IDs - remove for full analysis
  next if $_ =~ /NO Gene Ontology/; # discard results with no GO terms
  
  my @split = split( /\t/, $_ ); # split the file to an array
  my $locus = $split[0]; # use array addresses to access values eg. Locus ID

#  my @GOlist = split( /\; /, $split[5] ); # old format - GO was col# 5
  my @GOlist = split( /\; /, $split[7] ); # split the GO terms to an array
#  $refSize++ if (grep /P\:/, @GOlist);
  my $grepCnt = grep /P\:/, @GOlist;

  $refSize += $grepCnt if $grepCnt;

  foreach my $GOterm (@GOlist) {
    my ($g, $idNo, $namespace, $name) = split( /\:/, $GOterm ); # split each GO hit
    next unless $namespace =~ /P/; # comment to analyse all namespaces
      # P = biological_process, C = cellular_component, F = molecular_function
#    $refSize++; # count how many reference results have GO terms

    my $testTerm = "$g:$idNo"; # join up the GO & number parts

    if (exists $GOtree{$testTerm} ) {
#      print "OOPS: $GOtree{$testTerm}\n\n";
      $GOcountAll{$testTerm}++; # count the term
      print "TERM: $testTerm\tParents: ";

      foreach my $par (keys %{ $GOtree{$testTerm} }) {
	#print "\nCHECK par: %{ $GOtree{$testTerm} }\t$par\n\n";
	$GOcountAll{$par}++; # count the parent terms
	print " ", $par;
      }
    print "\n\n";
    }
#      print "\n\n";
  }
}

close FUNC_IN;

#print "REF: ", $refSize, "\tSAMP: ", $sampSize, "\n";

## if we want to get a sorted list of count vs GO terms
#foreach my $termTotal  (sort { $GOcountAll {$b} <=> $GOcountAll {$a}} keys %GOcountAll ){
#  print "$GOcountAll{$termTotal}\t$termTotal\n";
#}

print "GOid\tGOname\trefSize refPosHits\n"; # headings

foreach my $term (keys %GOcountAll ) {
    my $refPos = $GOcountAll{$term}; # get the count for reference set positives

    print $term, "\t", $GOdetails{$term}, "\t", $refSize, "\t", $refPos .
    "\n";
#  print "$GOcountDiff{$termTotal}\t$termTotal\n";
}