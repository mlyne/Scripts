#!/usr/bin/perl
#
#

use strict;
use warnings;
use feature ':5.12';

use Getopt::Std;
require LWP::UserAgent;
use SynbioRegionSearch qw/regionSearch/;
use JSON;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

#$/ = undef;

my $usage = "Usage: blast4bact.pl seq_in_file OUT_FILE

where in_file is tab delimited in the format:
\tsequenceID\tsequence

Options:
-h\tthis help
\n";

### command line options ###
my (%opts);
 
getopts('h', \%opts);
defined $opts{"h"} and die $usage;

unless ( $ARGV[1] ) { die $usage }

my ( $seq_file, $out_file ) = @ARGV;

open(SEQ_FILE, "< $seq_file") || die "cannot open $seq_file: $!\n";

my @queries;
while (<SEQ_FILE>) {
  chomp;
  my $line = $_;
  $line =~ s/^/>/;
  $line =~ s/\t/\n/;
  push(@queries, $line);
#  print "Q: ", $line, "\n";

}

close (SEQ_FILE);

open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";


# Set working directory
my $work_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/DATA/BLAST/MICROBES";

### TEST DATA ###
#my $query = ">EG10061\natgcagaccccgcacattcttatcgttgaagacgagttggtaacacg"; # test seq
#my $query = ">EG10061\natgctgcggggcattcaaaattgaagaaaaggtaacacg"; # test fail seq
# my $query = ">panB\nTTGCCCCCACCAATGTGACTGATAAAATGCCAGACA
# >mdoG\nTTGTCGGAATGGCTGGTTATCCATTAAAATAGATCGGA
# >gloA\nTTGTAATCCAACATTGCGAGCGGCGTAAAGCCGCCGCTATACTAAAACAAC
# >nlpD\nTTCAGTAGGGTGCCTTGCACGGTAATTATGTCACTGG
# >bcp\nTGTACAGAACTCAATGCACAAGGCAGTATTAACGTCGT
# >gcvR\nTTGTATGCATGTTTTTTTTATGCTTTCCTTAAGAACA";

# write query to a tmp file
open TMP_FILE, ">$work_dir/tmp_file.fa" or die $!; 
print TMP_FILE join("\n", @queries); 
close TMP_FILE;

# set BLAST params
#print "BLASTing sequence: $part_sequence\n"; ###
my $blast_db = "$work_dir/prokaryote_genomes";
my $blast_out = `blastn -query $work_dir/tmp_file.fa -db $blast_db -outfmt 6`;

#print "B: ", $blast_out, "\n"; ###

my @blast_res;
if ($blast_out =~ m/\n/) {
  @blast_res = split("\n", $blast_out);
} else {
  push(@blast_res, $blast_out);
}
#print join("\n", @blast_res), "\n";

# BLAST output 
# Field	 	Description
# 1	 	Query label.
# 2	 	Target (database sequence or cluster centroid) label.
# 3	 	Percent identity.
# 4	 	Alignment length.
# 5	 	Number of mismatches.
# 6	 	Number of gap opens.
# 7	 	1-based position of start in query. For translated searches (nucleotide queries, protein targets), query start<end for +ve frame and start>end for -ve frame.
# 8	 	1-based position of end in query.
# 9	 	1-based position of start in target. For untranslated nucleotide searches, target start<end for plus strand, start>end for minus strand.
# 10	 	1-based position of end in target.
# 11	 	E-value calculated using Karlin-Altschul statistics.
# 12	 	Bit score calculated using Karlin-Altschul statistics.

#my $region;
for my $result (@blast_res) {
  my ($q_name, $targ, $perc, $a_len, $mism, $gap, 
      + $q_start, $q_end, $db_start, $db_end, $other) = split("\t", $result);

# Test to see if we have results
  unless ($other) { 
    warn "No BLAST hits for QUERY\n";
  }

# grab host chromosome info ready for synbiomine query
  my $chromosome;
  if ($targ =~ /\|(NC_.+)\|/) {
    $chromosome = $1;
  } else {
    warn "No Chromosome found for $targ\n";
    next;
  }

# query region co-ordinates
  my ($organism_start, $organism_end, $organism_strand);

  if ($db_start < $db_end) {
    $organism_start = $db_start;
    $organism_end = $db_end;
    $organism_strand = "1";
  } else {
    $organism_start = $db_end;
    $organism_end = $db_start;
    $organism_strand = "-1";
  }

  my $region = "$chromosome:$organism_start..$organism_end";

  my ($gene_from_synbio, $expressionRef, @synbio_expr_results); 
  if ($perc > 99) {
    my ($org_short, $genesFromSynbio_Ref) = regionSearch($region);  # calls a module to query synbiomine for gene id

    unless ($genesFromSynbio_Ref) { # finish if we didn't find a gene
      print "Sorry. No gene found at $region in SynBioMine\n";
      next;
    }

    my @synbio_genes = @$genesFromSynbio_Ref;
    foreach my $synbio_gene (@synbio_genes) {
      my $symbol = $synbio_gene->[0];
      my $identifier = $synbio_gene->[1];
      print OUT_FILE "$q_name\t$identifier\t$chromosome:$organism_start..$organism_end\t$organism_strand\t$org_short\n";
    }

  } else {
    print "$q_name: BLAST hit for $region below cutoff: ", $perc, " percent identity\n";
    next;
  }

  unlink "$work_dir/tmp_file.txt";
}

close (OUT_FILE);


