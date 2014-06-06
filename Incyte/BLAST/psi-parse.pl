#!/usr/local/bin/perl -w
#
# 

# psi-parse.pl

# pragmas
use strict;

undef $/;

my @chunks;

while (<>) 
{
  chomp;
  @chunks = split(/Searching/, $_);
}

my @first_round = split(/\n/, $chunks[0]);
my $query;
foreach my $line (@first_round)
{
  if ($line =~ /Query= (.+)/)
  {
    $query = $1;
  }
}
      
my $failed;
$failed++ if $chunks[-1] !~ /CONVERGED/;

my @final_round;
@final_round = split(/\n/, $chunks[-1]);

my @hits;
my $round_count;
foreach my $pants (@final_round)
{
  if ($pants =~ /Results from round (\d+)/)
  {
    $round_count = $1;
  }

  if ($pants =~ /^(SW|TR|FP):/)
  {
#    print "$pants\n";
    push (@hits, $pants);
  }
}

my ($id, $score, $evalu);
my (@ids, @scores, @evalues);
unless ($failed)
{
  foreach my $hit (@hits)
  {
    ($id, $score, $evalu) = split(/\s+/, $hit);
    $evalu =~ s/^e-/1e-/;
    if ($evalu <= 1e-50)
    {
      push(@ids, $id);
      push(@scores, $score);
      push(@evalues, $evalu);
    }
  }
}

if (@ids)
{
  open(OUTFILE,  "> $query.list") || die "couldn't open $query.list: $!";
  foreach my $prot_id (@ids)
  {
    print OUTFILE "$prot_id\n";
  }
}


### Alternative code 
### - couldn't be bothered to use a sub routine :)
#  print "$query\n";
#  print scalar(@hits), 
#  " Hits found in $round_count rounds\n" if (@hits && $round_count);

#  print scalar(@hits), " Hits found\n" if ! $round_count;
#  print "Last Hit: $id\t$score\t$evalu\n";
#  print "Not Converged!\n" if $failed;
#  print "\n";
