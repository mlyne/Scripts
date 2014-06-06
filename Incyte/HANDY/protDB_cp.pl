#!/usr/local/bin/perl -w

# protDB_pfam.pl

# pragmas
use strict;

# standard
use FileHandle;
use Getopt::Long;

# modules

# globals


my $usage = "Usage: protDB_parse.pl [--help]

protDB_parse.pl <options> database(s)

\t--help   This list

Used for parsing items from Swissprot and SPTrembl
databases

Options:
\t--id     ProtDB Id
\t--acc    ProtDB Acc
\t--gene   Gene Symbol
\t--desc   Description Lines
\t--org    Organism
\t--pfam   Pfam acc\tPfam id\tdomain count

\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $comid, $comacc, $comgn, $comdesc, $comorg, $compfam);

GetOptions(\%opts, 'id', 'acc', 'gene', 'desc', 'org', 'pfam');
defined $opts{"help"} and die $usage;

defined $opts{"id"} and $comid++;
defined $opts{"acc"} and $comacc++;
defined $opts{"gene"} and $comgn++;
defined $opts{"desc"} and $comdesc++;
defined $opts{"org"} and $comorg++;
defined $opts{"pfam"} and $compfam++;

# mainline

STDOUT->autoflush (1);
STDERR->autoflush (1);
$/ = undef;

my $ifile;

foreach $ifile (@ARGV) 
{
  my $fpd = new FileHandle $ifile, "r";
  if (defined $fpd) 
  {
    print "reading $ifile\n";
    while (<$fpd>) 
    {
      chomp;
      my @entries = split(/\/\//, $_);

      $/ = "\n";
      
      foreach my $entry (@entries)
      {
	my @lines = split(/\n/, $entry);
	my $count;
	foreach my $line (@lines)
        {
	  chomp;
	  $count++;
          if ($line =~ /^ID\s+(\w+)\s+/)
          {
            my $id = $1;
	    print "$id\n" if $comid ;
          }

          if ($line =~ /^AC\s+(\w+);/)
          {
            my $acc = $1;
	    print "$acc\n" if $comacc;
          }

	  if ($line =~ /^GN\s+(\w+);/)
          {
            my $gn = $1;
	    print "$gn\n" if $comgn;
	  }

          if ($line =~ /^DE\s+([\S\s]+)/)
          {
	    my $desc = $1;
	    print "$desc\n" if $comdesc;
          }

          if ($line =~ /^OS\s+([\S\s]+)/)
          {
	    my $org = $1;
	    print "$org\n" if $comorg;
          }

          if ($line =~ /^DR\s+PFAM; ([\S\s]+)/)
          {
	    my $pfam = $1;
	    $pfam =~ s/\s//g;
	    $pfam =~ s/\.//;
	    my ($pfacc, $pfid, $pfcnt) = split(/;/, $pfam);
	    print "$pfacc\t$pfid\t$pfcnt\n" if $compfam;
          }

	  if ($count == @lines)
	  {
	    print "=\n";
	  }


	}
      }
    }
  }
}

