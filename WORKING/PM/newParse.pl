#!/usr/bin/perl
use strict;
use warnings;

#use BMTok;
use BioPorter;

my $usage = "Usage:terms2mesh.pl pubmed_xml\n";

unless ( $ARGV[1] ) { die $usage }

# Take input from the command line
my $inFile = $ARGV[0];
my $stopWords = $ARGV[1];

open(STOP, "< $stopWords") || die "cannot open $stopWords: $!\n";
my %stopHsh = ();

while (<STOP>) {
	chomp;
#	my $stopStr = $_;
	$stopHsh{$_}++;
}
close (STOP);

open(IFILE, "< $inFile") || die "cannot open $inFile: $!\n";

$/ = undef;

my @stemmed;
my @singles;

while (<IFILE>) {
  my $line = lc($_);
  $line =~ s/\n/ /g;
  $line =~ s/[^[:ascii:]]//g; # strip non-ascii
# $line =~ s/[^a-zA-Z\d\s]//g; # strip non letter number
  $line =~ s/[\{\}\[\]\(\)\:\;\!\?\,\.\>\<\#\'\\\/\%\"\=\*\|\&\@]/ /g; # strip special characters (\')
  $line =~ s/ - |- | -/ /g;
  $line =~ s/\&gt|\&lt|\&quot|\&amp//g;	# character codes
#  $line =~ s/&lt//g;	# character codes
#  $line =~ s/&quot//g;	# character codes
#  $line =~ s/&amp//g;	# character codes
  $line =~ s/\s+/ /g;	# multiple whitespaces
  
#  my $tokStr = tokenize("$line");
  my @words = split(/ /, $line);
  
  foreach my $word (@words)
  {
    push(@stemmed, porter("$word")) unless exists $stopHsh{$word};
  }
  
}

print join(" ", @stemmed), "\n";
#print $stemWd, "\n";