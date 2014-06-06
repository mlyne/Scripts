#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;

my $usage = "Usage:termXtract.pl terms2Mesh_file

Outputs Term or MeSH double or triple co-occurrence

Options:
\t-h\tThis help
\t-d\tsuppress double terms
\t-t\tsuppress triple terms
\t-m\tparse MeSH terms instead
\tminimum triple value [digit]
\tminimum double value [digit]\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $doub, $trip, $mesh);

getopts('hdtm', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"d"} and $doub++;
defined $opts{"t"} and $trip++;
defined $opts{"m"} and $mesh++;


#my $terms = "hip arthroplasty, harris hip, hip pain, ankylosing spondylitis, back pain, bilateral thr, ankylosed hip, flexion deformity, pain postoperatively, ankylosed hips, hip, arthroplasty, thr, pain, hips, postoperative, cement, harris, postoperatively, bilateral, lateral, hhs, flexion, attention, core, back, deformity, disc, spondylitis, ankylosing";

#my $terms = "hip arthroplasty, harris hip, hip pain, ankylosing spondylitis, back pain, bilateral thr, ankylosed hip, flexion deformity, pain postoperatively, ankylosed hips, ankylosed hips, ankylosed hips, hip, arthroplasty, thr, pain, hips, postoperative, postoperative, postoperative, cement, harris, postoperatively, bilateral, lateral, hhs, flexion, attention, core, back, deformity, disc, spondylitis, ankylosing";

my $inFile = $ARGV[0];
my $minCountT = ($ARGV[1]) ? $ARGV[1] : 0;
my $minCountD = ($ARGV[2]) ? $ARGV[2] : 0;

open(IN_FILE, "< $inFile")  || die "cannot open $inFile: $!";

my %doubleTerms;
my %tripleTerms;

my $term = ($mesh) ? "MESH HITS" : "TERM HITS";

while (<IN_FILE>)
{
  if (/$term/)
  {
    chomp;
    $_ =~ s/.+HITS\: //;
#    $_ =~ s/MESH HITS\: // if $mesh;
    my @terms = split(/, /, $_);
    @terms = sort(@terms);
#    print join(",", @terms), "\n";
  
    while ( scalar(@terms) > 0)
    {
      my $term1 = shift(@terms);
  
      foreach my $count (0..$#terms)
      {
	my $dT = $term1."\t".$terms[$count];
#    	print $dT, "\n";
#    	print $term1, "\t", $terms[$count], "\n";
	$doubleTerms{$dT} += 1;
	
	if ($count < $#terms)
	{
	  my $count2 = ($count +1);

	  foreach my $cadd ($count2..$#terms)
	  {
	    my $tT = $term1."\t".$terms[$count]."\t".$terms[$cadd];
#	    print $tT, "\n";
	    $tripleTerms{$tT} += 1;
	  }
	 }
      }
    }


  } # if block
} # WHILE block

close(IN_FILE);

while ( my ($key, $value) = each %tripleTerms) 
{
 if ($value >  $minCountT) {print $value, "\t", $key, "\n" unless $trip; }
} 

while ( my ($key, $value) = each %doubleTerms) 
{
 if ($value > $minCountD) {print $value, "\t", $key, "\n" unless $doub; }
} 