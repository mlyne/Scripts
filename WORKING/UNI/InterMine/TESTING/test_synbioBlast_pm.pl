#!/usr/bin/perl

use strict;
use warnings;

use feature ':5.12';

use BlastSynbio qw/run_BLAST/;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

# Set working directory
my $work_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/DATA/BLAST/Bsub168";

my $debug++;

my $id = "test1";
my $seq = "TTTTACTTCTAATATTTAGTGTTATAATA";
my $len = length($seq);
my $query = ">$id\n$seq";

my $region_ref = run_BLAST($query, $len, $work_dir, $debug);

