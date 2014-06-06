#!/usr/local/bin/perl -w

# protDB_pfam.pl

# pragmas
use strict;

# standard
use FileHandle;
use Getopt::Long;

# modules

my $usage = "Usage: protDB_parse.pl [--help]

protDB_parse.pl <options> database(s)

\t--help   This list

Used for parsing items from Swissprot and SPTrembl
databases

Options:
\t--id         ProtDB Id
\t--acc        ProtDB Acc
\t--desc       Description Lines
\t--gene       Gene Symbol
\t--org        Organism
\t--title      Paper Title
\t--comment    Comments
\t--pfam       Pfam acc\tPfam id\tdomain count

\n";

#unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $comid, $comacc, $comgn, $comdesc, $comorg, $comtitle, $comcc, $compfam);

GetOptions(\%opts, 'help', 'id', 'acc', 'gene', 'desc', 'org', 'title', 'comment', 'pfam');
defined $opts{"help"} and die $usage;

defined $opts{"id"} and $comid++;
defined $opts{"acc"} and $comacc++;
defined $opts{"gene"} and $comgn++;
defined $opts{"desc"} and $comdesc++;
defined $opts{"org"} and $comorg++;
defined $opts{"title"} and $comtitle++;
defined $opts{"comment"} and $comcc++;
defined $opts{"pfam"} and $compfam++;

# globals
my ($pfacc, $pfid, $pfcnt);
my (@new_entry, @id, @acc, @gn, @org, @desc, @title, @comment, @pfam);

# mainline

STDOUT->autoflush (1);
STDERR->autoflush (1);
$/ = undef;

my $ifile;

foreach $ifile (@ARGV) 
{
  my $fh = new FileHandle $ifile, "r";
  if (defined $fh) 
  {
    print "***reading $ifile***\n";
    while (<$fh>) 
    {
      chomp;
      my @entries = split(/\/\/\n/, $_);
      
      $/ = "\n";

      foreach my $entry (@entries)
      {
	my @lines = split(/\n/, $entry);
	    
	foreach my $line (@lines)
	{
	  chomp;
	  if ($line =~ /^ID\s+(\w+)\s+/)
	  {
	    my $id = $1;
	    push(@id, $id) if $comid;
	  }
	      
	  if ($line =~ /^AC\s+(\w+)\;/)
	  {
	    my $acc = $1;
	    push(@acc, $acc) if $comacc;
	  }
	    
	  if ($line =~ /^DE\s+([\S\s]+)/)
	  {
	    my $desc = $1;
	    push(@desc, $desc) if $comdesc;
	  }
	    
	  if ($line =~ /^GN\s+(.+)\.*/)
	  {
	    my $gn = $1;
	    push(@gn, $gn) if $comgn;
	  }
	    
	  if ($line =~ /^OS\s+([\S\s]+)/)
	  {
	    my $org = $1;
	    push(@org, $org) if $comorg;
	  }

	  if ($line =~ /^RT\s+([\S\s]+)/)
	  {
	    my $title = $1;
	    push(@title, $title) if $comtitle;
	  }

	  if ($line =~ /^CC   ([\S\s]+)/)
	  {
	    my $comment = $1;
	    $comment =~ s/-\!-//;
	    $comment =~ s/^   //;
	    $comment =~ s/^--.+//;
	    $comment =~ s/^\w+.+//;
	    push(@comment, $comment) if $comcc;
	  }

	  if ($line =~ /^DR\s+PFAM; ([\S\s]+)/)
	  {
	    my $pfam = $1;
	    $pfam =~ s/\s//g;
	    $pfam =~ s/\.//;
	    ($pfacc, $pfid, $pfcnt) = split(/;/, $pfam);
	    push(@pfam, "$pfacc\t$pfid\t$pfcnt") if $compfam;
	  }
	}
	  

	print "ID: ", @id, "\n" if @id;
	print "AC: ", @acc, "\n" if @acc;
	print "DE: ", join(' ', @desc), "\n" if @desc;
	print "GN: ", @gn, "\n" if @gn;
	print "OS: ", @org, "\n" if @org;
	print "RT: ", join(' ', @title), "\n" if @title;
	print "CC: ", join(' ', @comment), "\n" if @comment;
	print "PF: ", join(', ', @pfam), "\n" if @pfam;
	print "=\n";
	  
	(@id, @acc, @desc, @gn, @org, @title, @comment, @pfam) = ();
	
      }
    }
  }
}

