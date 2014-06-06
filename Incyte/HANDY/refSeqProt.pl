#!/software/arch/bin/perl
#
#

use strict;
use Getopt::Std;
use FileHandle;

my $usage = "\nUsage:refSeqProt [-h] [-g] refSeq.gbff\n
Description:
Process refseq GB flat files to return protein Id or Gene Symbol
Usually kept in /d2/databases/LocusLink/

Options:
\t-h\tThis help
\t-g\tGene Symbol

`-g` option returns: RefSeqId GeneSymbol
Default returns: RefSeqId proteinId\n
";

### command line options ###
my (%opts, $geneSym);

getopts('hg', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"g"} and $geneSym++;

STDOUT->autoflush (1);
STDERR->autoflush (1);
$/ = undef;

my $ifile;
my ($loc, $val);
my %hash = {};

foreach $ifile (@ARGV) 
{
  my $fh = new FileHandle $ifile, "r";
  if (defined $fh) 
  {
    while (<$fh>) 
    {
      chomp;
      my @entries = split(/\/\/\n/, $_);
      
      $/ = "\n";

      foreach my $entry (@entries)
      {

	undef $loc;
	undef $val;

        my @lines = split(/\n/, $entry);

	my ($loc_line) = grep { /^LOCUS/ } @lines;
	if ($loc_line =~ /(NM_\d+) /) {
	  $loc = $1;
	}

	if ($geneSym) {
	  my ($prot_line) = grep { /\/gene\=/ } @lines;
	  if ($prot_line =~ /gene\=\"(\S+)\"/) {
	    $val = $1;
	  }

	} else {
	  my ($prot_line) = grep { /protein_id\=/ } @lines;
	  if ($prot_line =~ /(NP_\d+)\.\d+/) {
	    $val = $1;
	  }
	}

	$hash{$loc} = "$val";
      
      }
    }
  }
}

while (my ($loc, $val) = each %hash) {
  print "$loc\t$val\n";
}
