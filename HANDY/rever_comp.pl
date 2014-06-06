#!/usr/bin/perl -w
#
#
#

# comment out line 25 to get rev comp
# comment out line  26 to just get comp
# comment out line 22 & 25 to just get rev

use strict;
use Getopt::Long;

my $usage = "Usage: rever_comp.pl <options> file

\tOptions:
\t--help\tThis list

\t--reverse\tGives the reverse of your sequence
\t--complement\tGives the Complement of your sequence

Combining -r and -c gives the reverse complement of your sequence.

\n";

### command line options ###
my (%opts, $reverse, $complement);

GetOptions(\%opts, 'help', 'reverse', 'complement');
defined $opts{"help"} and die $usage;

defined $opts{"reverse"} and $reverse++;
defined $opts{"complement"} and $complement++;

#unless ( $ARGV[0]) { die $usage }

my ($header, $seq);
my @bases = ();
my @rev_bases = ();
my @sequence = ();

READ_LOOP: while (<>) 
{
  chomp;
  if ($_ =~ /^>/)
  {
    $header = $_;
    print "$header\n";
    next;
  }

  ($seq) = ($_);
  $seq =~ tr/[actgACTGxX]/[tgacTGACnN]/ if $complement; 
  @bases = split(//, $seq);
  @rev_bases = reverse(@bases);
  push(@sequence, [@bases]) unless $reverse;
  unshift (@sequence, [@rev_bases]) if $reverse;

  next READ_LOOP;
}

for my $i(@sequence)
{
  print @{$i}, "\n";
}

