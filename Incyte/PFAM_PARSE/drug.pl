#!/usr/local/bin/perl -w
#
#
#

use strict;

$| = 1;
$/ = undef;

my $catdata = $ARGV[0];
my $res_file = $ARGV[1];

open(CATDATA, "< $catdata") || die "cannot open $catdata: $!";

my @drug_records = ();

while (<CATDATA>)
{
  chomp;
  @drug_records = split(/=\n/, $_);
}

close(CATDATA) || die "cannot close $catdata: $!";


$/ = "\n";

my ($record, @pfam_records, $pfam_line);
my ($drg_cat, $domain);
my (@test, @test2);

foreach $record (@drug_records)
{
  @pfam_records = split(/\n/, $record);

  @test = ();

  foreach $pfam_line (@pfam_records)
  {
    if (($pfam_line =~ /([\w-]+):/) 
	&& ($pfam_line !~ /\#/))
    {
      $drg_cat = $1 ;
      push(@test, $drg_cat);
    }

    if ($pfam_line =~ /^\s+(\S+)\s\#/)
    {
      $domain = $1;
      push(@test, $domain);
    }

    if (scalar(@test) == scalar(@pfam_records))
    {
      push(@test2, [@test]);
    }

  }
}

my (%pfam_assoc, @result);

for my $entry (0 .. $#test2)
{
#  print "@{$test2[$entry]}\n";

  @result = @{$test2[$entry]};

  for my $i (1 .. $#result)
  {
    push( @{$pfam_assoc{$result[0]}}, "$result[$i]");
  }
}

my @in_entry = ();
open(RESFILE, "< $res_file") || die "cannot open $res_file: $!";

while (<RESFILE>)
{
  chomp;
  s/://;
  @in_entry = split(/\s+/, $_);
  my $locusID = $in_entry[0];

  for my $locusDom (1 .. $#in_entry)
  {
    foreach my $pfam_keys (keys %pfam_assoc)
    {
      my @pants = @{$pfam_assoc{$pfam_keys}};
      foreach my $pant (@pants)
      {
	if ( "$in_entry[$locusDom]" eq "$pant" )
	{
	  print "$locusID\t$pant\t$pfam_keys\n";
	}
      }
    }
  }


}

close(RESFILE) || die "cannot close $res_file: $!";


#foreach my $pfam_keys (keys %pfam_assoc)
#{
#  print "$pfam_keys has @{$pfam_assoc{$pfam_keys}}\n";
#}
