#!/usr/local/bin/perl -w 

#
#
#

use strict;

$| = 1;
$/ = undef;

my @files = ();
my @entry = ();
my @line = ();
my ($entline, $cropcode);
my @Hit_files = ();

@files = <*.txt>;

for my $i (@files)
{
  open (FILE, "< $i") or die "Could not open $i: $!\n";
  while (<FILE>)
  {
    chomp;
    if ($_ =~ /Adip/) 
    {
      undef $cropcode;
      @entry = split(/\n/, $_);
      for $entline (@entry)
      {
	if (($entline =~ /^0/) && ($entline =~ /Adip/))
	{
	  $cropcode++;
	}
      }

      push(@Hit_files, $i) if $cropcode;
    }
  }
  close(FILE) or die "Could not close $i: $!\n";
}


$/ = "\n";
my $adip_count = 0;
my $s;

for $s (@Hit_files)
{
  open (HEADER, "> $s.header") or die "Could not open $s.header: $!\n";
  open (DATA, "> $s.data") or die "Could not open $s.data: $!\n";

  open (HITFILE, "< $s") or die "Could not open $s: $!\n";

  while (<HITFILE>)
  {
    chomp;
    print HEADER "$_\n" if ($_ =~ /^\#/);
    print DATA "$_\n" if ($_ =~ /^0/);
  }

  close(HITFILE) or die "Could not close $s: $!\n";
}

close(HEADER) or die "Could not close $s.header: $!\n";
close(DATA) or die "Could not close $s.data: $!\n";
