#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use feature ':5.12';

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:authAddrMerge.pl authFreqAddr > out

Format: TAB seperated auth address file
id[TAB]Freq[TAB]Auth[TAB]Address
\n";

unless ( $ARGV[0] ) { die $usage }

my $termFile = $ARGV[0];
#my $outFile = $ARGV[1];

open(IFILE, "< $termFile") || die "cannot open $termFile: $!\n";
#open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";
#binmode(OUT_FILE, 'utf8');

my %authHash = ();
my ($id, $freq, $auth, $addr); 
while (<IFILE>) 
{
  shift;
  chomp;
  ($id, $freq, $auth, $addr) = split(/\t/, $_);
  
   if ( exists $authHash{$auth} )
   {
    $authHash{$auth}[0] += $freq;
    $authHash{$auth}[1] .= "\; $freq $id";
   } else {
   #$authHash{$auth} = [$freq, [$id], $addr];
    $authHash{$auth} = [$freq, "$freq $id", $addr];
   }
}

foreach my $key (sort { $authHash {$b} <=> $authHash {$a} } keys %authHash) 
{
  say $authHash{$key}[0], "\t", $key, "\t", $authHash{$key}[1], "\t", $authHash{$key}[2];
}

close (IFILE);
#close (OUT_FILE);