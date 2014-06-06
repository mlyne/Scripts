#!/usr/bin/perl
# 


use Getopt::Std ;
use strict;

$|=1;

my $usage = "Usage:sim4toArt.pl [-h] [-c <cDNAfile>] [-g <genomic>] [-n <name>]\n";

unless ( $ARGV[0] ) { die $usage }

my (%opts, $cdna, $bac, $name);
getopt('hc:g:n:', \%opts);

defined $opts{"h"} and die $usage;

defined $opts{"c"} and $cdna = $opts{"c"} or die "no cDNA file specified\n";
defined $opts{"g"} and $bac = $opts{"g"} or die "no genomic DNA file specified\n";
defined $opts{"n"} and $name = $opts{"n"} or die "no name specified\n";

my @sim4 = ();

@sim4 = `sim4 $cdna $bac P=1`;

my @exoncoords = ();
my $rev = 0;
my @CDS = ();

foreach my $s (@sim4){
  $rev++ if $s =~ /complement/;

  if ($s =~ /^\d/){
    $s =~ s/\-/../g;
    $s =~ s/[()\>%]//g;

    my $coords;
    (undef, $coords) = split /\s+/, $s;
    push( @CDS, $coords );
    
  }
}

my $spliced;
$spliced++ if (@CDS > 1);

print "FT   CDS             ";
print "join(" if $spliced;
print "complement(" if $rev;
print join(',', @CDS);
print ")" if $spliced;
print ")" if $rev;
print "\n";
print "FT                   /colour=4\n";
print "FT                   /label=$name\n";
