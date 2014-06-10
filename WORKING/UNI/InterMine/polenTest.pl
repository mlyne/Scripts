#!/usr/bin/perl
#
#

use strict;
use warnings;

my $source_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/DATA/BLAST/EcoliMG1665";

my $out = `java -jar $source_dir/polenClient.jar`;
print $out, "\n";