#!/usr/bin/perl
use strict;
use warnings;
use Statistics::Descriptive;

my @data = (6, 9, 7, 23, 30, 18);
my @data2 = (10, 5, 8, 11);
my @data3 = (12, 15, 13, 19, 5, 8, 10);
my @clear;

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@data); 
my $mean = $stat->mean();
my $var  = $stat->variance();
my $sd = $stat->standard_deviation();
print "Data1: mean: $mean\nvariance $var\nStd Deviation: $sd\n";

$stat->clear();
$stat->add_data(@data2); 
$mean = $stat->mean();
$var  = $stat->variance();
$sd = $stat->standard_deviation();
print "Data2: mean: $mean\nvariance $var\nStd Deviation: $sd\n";

$stat->add_data(@clear);
$stat->add_data(@data3); 
$mean = $stat->mean();
$var  = $stat->variance();
$sd = $stat->standard_deviation();
print "Data3: mean: $mean\nvariance $var\nStd Deviation: $sd\n";
