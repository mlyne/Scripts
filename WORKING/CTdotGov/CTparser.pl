#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use XML::Simple;
use Data::Dumper;

my $usage = "Usage:CTparser.pl trial_file.xml\n

Options:
\t-h\tThis help
\tother\n";

### command line options ###
my (%opts, $siteOpt, $intervenOpt, $dumper);

getopts('hsid', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"s"} and $siteOpt++;
defined $opts{"i"} and $intervenOpt++;
defined $opts{"d"} and $dumper++;

unless ( $ARGV[0] ) { die $usage }

my $fileOfFiles = $ARGV[0];

open(IFILE, "< $fileOfFiles") || die "cannot open $fileOfFiles: $!\n";
my @entries;

while (<IFILE>)
{

chomp;
print $_, "\n";

my $xmlFile = $_;
my $xmlRef = XMLin($xmlFile);

print Dumper($xmlRef) if $dumper;

&invest_sites($xmlRef) if ($siteOpt);
&drug_intervention($xmlRef) if ($intervenOpt);

}
close(IFILE);


### Sub routines ###

sub invest_sites {

my $data = shift;

my @siteInfo;

  # check whether it is a single value or an arrayref of values
  if (ref $data->{location} eq 'ARRAY') {
    @siteInfo = @{ $data->{location} }; # dereference the arrayref to get an AoH
  } else {
    @siteInfo = $data->{location}; # just get the single value
  }

  foreach my $site (@siteInfo) {
    my $investigator = ($site->{investigator}->{last_name}) ? $site->{investigator}->{last_name} : "no_name";
    my $facility = ($site->{facility}->{name}) ? ($site->{facility}->{name}) : "no_facility";

    print $investigator, "\t", $facility, "\n";
  }
}

sub drug_intervention {

my $data = shift;

my @intervenInfo;

#print ref $xmlRef->{intervention}, "\n";

  if (ref $data->{intervention} eq 'ARRAY') {
    @intervenInfo = @{ $data->{intervention} }; # dereference the arrayref to get an AoH
  } else {
    @intervenInfo = $data->{intervention}; # just get the single value
  }

  foreach my $interven (@intervenInfo) {
#print $interven->{intervention_type}, "\n";

    if ($interven->{intervention_type} =~ /Drug/) {
      my $regime = ($interven->{description}) ? ($interven->{description}): "no_descr";
      my $drug = ($interven->{intervention_name}) ? ($interven->{intervention_name}): "no_drug";

      print $drug, "\t", $regime, "\n";
    }
  }

}


