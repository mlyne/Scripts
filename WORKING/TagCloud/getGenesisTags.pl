#!/usr/bin/perl

use HTTP::Cache::Transparent;
use LWP::Simple;
use Data::Dumper;

use strict;
use warnings;

$Data::Dumper::Terse= 1;  # avoids $VAR1 = * ; in dumper output

HTTP::Cache::Transparent::init( {
    BasePath => './cache',
    NoUpdate  => 30*60
  } );

# specify where to get the bible, and the desired verses
my $url = 'http://www.gutenberg.org/dirs/etext05/bib0110.txt';
my $ofilename = "genesis.pl";

# get the text
my $txt = get($url);

# Remove Project Gutenberg Header
$txt =~ s/^.*\*\*\* START OF THE PROJECT GUTENBERG[^\n]*\n//s;
# skip the preface
$txt =~ s/^.*(\nBook 01)/$1/s;
# Remove Project Gutenberg Trailer
$txt =~ s/\*\*\* END OF THE PROJECT GUTENBERG.*$//s;

# remove most punctuation
$txt =~ s/[^\w\'\-]/ /gs;

# convert text into individual words and count 'em
my $tags;

foreach my $w (split /\s+/, $txt)
{
  next if $w =~ /[0-9]/;  # skip paragraph numbers and other numbers
  next if $w eq '';
  my $uw = uc($w);
  $tags->{$uw} = {url=>'http://dictionary.reference.com/search?q='.$w, count=>0, tag=>$w} if !(defined $tags->{$uw});
  $tags->{$uw}->{count}++;
}

open (OFILE, ">$ofilename") or die ("Can't open $ofilename file for $ofilename ");
print OFILE "package mytags;\n\n\$tags = " . Dumper($tags) . ";\n1;\n";
close OFILE;

printf "Wrote %d tags to $ofilename \n", scalar(keys %{$tags});
