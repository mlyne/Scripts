#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;

my $usage = "Usage:termReFreq.pl termMesh_file\n

Options:
\t-h\tThis help\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts);

getopts('h', \%opts);
defined $opts{"h"} and die $usage;


#my $terms = "hip arthroplasty, harris hip, hip pain, ankylosing spondylitis, back pain, bilateral thr, ankylosed hip, flexion deformity, pain postoperatively, ankylosed hips, hip, arthroplasty, thr, pain, hips, postoperative, cement, harris, postoperatively, bilateral, lateral, hhs, flexion, attention, core, back, deformity, disc, spondylitis, ankylosing";

#my $terms = "hip arthroplasty, harris hip, hip pain, ankylosing spondylitis, back pain, bilateral thr, ankylosed hip, flexion deformity, pain postoperatively, ankylosed hips, ankylosed hips, ankylosed hips, hip, arthroplasty, thr, pain, hips, postoperative, postoperative, postoperative, cement, harris, postoperatively, bilateral, lateral, hhs, flexion, attention, core, back, deformity, disc, spondylitis, ankylosing";

my $inFile = $ARGV[0];
open(IN_FILE, "< $inFile")  || die "cannot open $inFile: $!";

my %termFreq;

while (<IN_FILE>)
{
  if (/TERM HITS/)
  {
    chomp;
    $_ =~ s/TERM HITS\: //;
    $termFreq{$_}++ for split(/, /, $_);
   }

} # WHILE block

close(IN_FILE);

while ( my ($key, $value) = each %termFreq) 
{
 if ($value > 1) {print "$value\t$key\n"; }
#print "$value\t$key\n";
} 
