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

my $usage = "Usage:authAddr_addEmail.pl authFreqAddr PI.file > out

Format: TAB seperated auth address file
id[TAB]Freq[TAB]Auth[TAB]Address
\n";

unless ( $ARGV[1] ) { die $usage }

my $authFile = $ARGV[0];
my $piFile = $ARGV[1];
my $outFile = $ARGV[2];

open(AFILE, "< $authFile") || die "cannot open $authFile: $!\n";
open(PIFILE, "< $piFile") || die "cannot open $piFile: $!\n";

#my ($title, $f_name, $s_name, $email_1, $email_2, $rest);

open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";
binmode(OUT_FILE, 'utf8');

my %piHash = ();

while (<PIFILE>) 
{
  next if ($_ =~ /\#/);
  chomp;
  my (undef, $f_name, $s_name, $email_1, $email_2, $rest) = split(/\t/, $_, 6);
  $piHash{$s_name} = [$f_name, $s_name, $email_1, $email_2, $rest];
  
}
close (PIFILE);

#my ($id, $freq, $auth, $addr, $a_email); 
while (<AFILE>) 
{
  next if ($_ =~ /Paper Count/);
  chomp;
  
  my ( $freq, $auth, $cat, $addr, $a_email, undef ) = split(/\t/, $_);
#  say "$freq, $auth, $cat, $addr, $a_email";
  
  if ($a_email) { say OUT_FILE $_ ; next; }
  
  my ($surn, $init) = split(/ /, $auth);
  
   if ( exists $piHash{$surn} )
   {
#    $piHash{$auth}[0] += $freq;
#    $piHash{$auth}[1] .= "\; $freq $id";
     print OUT_FILE $_;
     print OUT_FILE "\t", $piHash{$surn}[0], " ",($piHash{$surn}[1]);
     print OUT_FILE "\t", $piHash{$surn}[2] if ($piHash{$surn}[2]);
     print OUT_FILE "\t", $piHash{$surn}[3] if ($piHash{$surn}[3]);
     print OUT_FILE "\n";
 
   } else {
    say OUT_FILE $_ ;
   }
}

close (AFILE);
close (OUT_FILE);


