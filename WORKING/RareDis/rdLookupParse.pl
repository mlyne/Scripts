#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage: rdLookupParse.pl rareDis_lookup_file

File containing:
1. OrphaNet disesae name
2. abbrev. synonyms list
3. OrphaNet ID
4. Prevalence
5. Onset
6. Death
7. Inheritance

\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
# my (%opts, $noMesh, $meshStyle);
# 
# getopts('hns', \%opts);
# defined $opts{"h"} and die $usage;
# defined $opts{"n"} and $noMesh++;
# defined $opts{"s"} and $meshStyle++;


# Take input files from the command line
my $file = $ARGV[0];

open FILE_IN, "$file" or die "can't open $file\n";

print "DisShort\tDisease\tSynonyms\tOrphaNetID\tPrevalence\tOnset\tMortality\tInheritance\n";

while (<FILE_IN>) {
  chomp $_;
  my $line = lc($_);
  my ($dis, $syn, $id, $prev, $onset, $death, $inher) = split("\t", $line);
  
  my @alias = split("\; ", $syn);
  my $disShort = shift(@alias);
  
  print $disShort, "\t";
  
  $dis =~ s/\"//g;
  $syn = "" if ($syn =~ /nosyn/);
  print $dis, "\t", $syn, "\t", $id, "\t"; 
  
  if ($prev =~ /\d/) {
    my $prevExpr = $prev;
    $prev =~ s/^\<//;
    $prev =~ s/1-//;
    $prev =~ s/ //g;
    $prev =~ s/\//\t/;
    $prev =~ /^(\d)\t(\d+)$/;
    my ($vara, $varb) = ($1, $2);

    print $prevExpr, "\t", $vara/$varb, "\t" if $vara;
  } else {print "", "\t", 0, "\t" }
  
  $onset =~ s/ //g;
  $onset =~ s/\//_/;
  $onset = "" if ($onset =~ /noonset/);
  print $onset, "\t";
  
  $death =~ s/ \/ /_/;
  $death = "" if ($death =~ /nodeath/);
  $death = "" if ($death =~ /no data avai/);
  print $death, "\t";
  
  $inher = "" if ($inher =~ /noinher/);
  $inher = "" if ($inher =~ /unknow/);
  $inher =~ s/\//_/;
  print $inher, "\n";
  
}
  