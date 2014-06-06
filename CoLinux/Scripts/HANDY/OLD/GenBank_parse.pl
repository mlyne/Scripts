#!/usr/local/bin/perl -w

# GenBank_parse.pl

# pragmas
use strict;

# standard
use FileHandle;
use Getopt::Long;

# modules

my $usage = "Usage: GenBank_parse.pl [--help]

protDB_parse.pl <options> database(s)

\t--help   This list

Used for parsing items from Swissprot and SPTrembl
databases

Options:
\t--locus          GenBank Locus
\t--def            Definition
\t--acc            GenBank Acc
\t--key            Keywords
\t--org            Organism
\t--title          Paper Title

\n";

#unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $comlocus, $comdef, $comacc, $comkey, $comorg, $comtitle);

GetOptions(\%opts, 'help', 'locus', 'def', 'acc', 'key', 'org', 'title');
defined $opts{"help"} and die $usage;

defined $opts{"locus"} and $comlocus++;
defined $opts{"def"} and $comdef++;
defined $opts{"acc"} and $comacc++;
defined $opts{"key"} and $comkey++;
defined $opts{"org"} and $comorg++;
defined $opts{"title"} and $comtitle++;


# globals
my ($pfacc, $pfid, $pfcnt);
my (@new_entry, @locus, @def, @acc, @key, @org, @title);

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
	  if ($line =~ /^LOCUS\s+(\w+)\s+/)
	  {
	    my $locus = $1;
	    push(@locus, $locus) if $comlocus;
	  }

	  if ($line =~ /^DEFINITION\s+([\S\s]+)/)
	  {
	    my $def = $1;
	    push(@def, $def) if $comdef;
	  }
	      
	  if ($line =~ /^ACCESSION\s+(\w+)\;/)
	  {
	    my $acc = $1;
	    push(@acc, $acc) if $comacc;
	  }
	    
	  if ($line =~ /^KEYWORDS\s+([\S\s]+)/)
	  {
	    my $key = $1;
	    push(@key, $key) if $comkey;
	  }
	    
	  if ($line =~ /^  ORGANISM\s+([\S\s]+)/)
	  {
	    my $org = $1;
	    push(@org, $org) if $comorg;
	  }

	  if (($line =~ /TITLE/ ... /JOURNAL/)
	      && ($line !~ /^  TITLE     Direct Submission/))
	  {
	    $line =~ s/  TITLE     //;
	    $line =~ s/            //;
	    $line =~ s/  JOURNAL.+//;
	    my $title = $line;
	    push(@title, $title) if $comtitle;
	  }
	  
	}

	print "LOCUS: ", @locus, "\n" if @locus;
	print "DEFINITION: ", join(' ', @def), "\n" if @def;
	print "ACCESSION: ", @acc, "\n" if @acc;
	print "KEYWORDS: ", @key, "\n" if @key;
	print "ORGANISM: ", @org, "\n" if @org;
	print "TITLE: ", join(' ', @title), "\n" if @title;
	print "=\n";
	  
	(@locus, @def, @acc, @key, @org, @title) = ();
	
      }
    }
  }
}

