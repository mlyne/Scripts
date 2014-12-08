#!/usr/bin/perl

use strict;
use warnings;
use feature ':5.12';

my @arr = qw|S1 arfW cimA S3 NA arfB cimD NA S53|;
my @sym = grep (!/^S\d/ && !/^NA/, @arr);

say join("-", @sym);