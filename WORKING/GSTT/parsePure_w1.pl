#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;

use feature ':5.12';

# Print unicode to standard out
binmode(STDOUT, 'utf8');

my $usage = "Usage:termMeshGrantXtract.pl pubmed_xml search_term_file

Options:
\t-h\tThis help
\n";

#unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $noMesh, $meshStyle);

getopts('h', \%opts);
defined $opts{"h"} and die $usage;
#defined $opts{"n"} and $noMesh++;
#defined $opts{"s"} and $meshStyle++;


# Take input from the command line

my $pubFile = $ARGV[0];

open(IFILE, "< $pubFile") || die "cannot open $pubFile: $!\n";

$/ = undef;

my @entries;

while (<IFILE>)
{
  @entries = split(/\n\n/, $_);
}


# Close the file we've opened
close(IFILE);

$/ = "\n";

foreach my $entry (@entries)
{
#  next unless $entry =~ m/TY  - JOUR/;
 
  my @lines = split("\n", $entry);
  s/\?s/\'s/ for @lines;
  
  # Publication type
  my @type = grep /^M1  - /, @lines;
  s/M1  - // for @type;
  next unless $type[0] =~ m/Article/;
 
  # Process Title
  my @title_lines = grep /^T\d  - /, @lines;
  s/T\d  - // for @title_lines;
 
  # Authors
  my @auth_lines = grep /^AU  - /, @lines;
  s/AU  - // for @auth_lines;
  my @auth_last = @auth_lines;
  s/,.+// for @auth_last;
  
  # Journal title
  my @jo = grep /^JO  - /, @lines;
  s/JO  - // for @jo;
  my $journal = $jo[0];
  
  # DOI
  my @do = grep /^DO  - /, @lines;
  s/DO  - // for @do;
  my $doi = ($do[0]) ? "$do[0]" : "no doi";
  
  # Citation info
  my @py = grep /^PY  - /, @lines;
  s/PY  - // for @py;
  my $year = $py[0];
  
  my @is = grep /^IS  - /, @lines;
  s/IS  - // for @is;
  my $issue = ($is[0]) ? "$is[0]" : "no issue";
  
  my @vl = grep /^VL  - /, @lines;
  s/VL  - // for @vl;
  my $volume = ($vl[0]) ? "$vl[0]" : "no vol";
  
  my @sp = grep /^SP  - /, @lines;
  s/SP  - // for @sp;
  my $start_page = $sp[0];
  
  my @ep = grep /^EP  - /, @lines;
  s/EP  - // for @ep;
  my $end_page = $ep[0];
  
  my $pp;
  if ($start_page and $end_page) {
    $pp = ($end_page >= $start_page) ? "$start_page" . "-" . "$end_page" : "$start_page";
  } elsif ($start_page) {
    $pp = $start_page;
  }
  
  my $citation = ($pp) ? "$issue\($volume):$pp" : "$issue\($volume)";
  
  say "start";
  say join("; ", @title_lines);
  say join("; ", @auth_lines);
  say $journal;
  say $citation;
  say $doi;
  print join("\[au\] AND ", @auth_last), "\[au\]\n";
  say "end";
}


