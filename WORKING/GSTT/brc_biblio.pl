#!/usr/bin/env perl
use strict;
use warnings;

use utf8;
use open qw(:std :utf8);
use feature ':5.12';

# Print unicode to standard out
#binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:brc_biblio.pl termFile biblioFile 

termFile format: # \t term
biblioFile format: # \t TAB separated publications file

Finds identical matches to a term set in a bibliography file\n";

unless ( $ARGV[2] ) { die $usage }

my $tFile1 = $ARGV[0];
my $biblioFile = $ARGV[1];
my $outFile = $ARGV[2];

open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";
binmode(OUT_FILE, 'utf8');

open(T1_FILE, "< $tFile1") || die "cannot open $tFile1: $!\n";
my @terms;
my %abbrHash = ();
my %jTitleHash = ();
my %origTitleHash = ();
my %foundAbbr =();

while (<T1_FILE>) {
  chomp;
#  my ($title, $abbr) = split(/\t/, $_);
  my ($abbr, $title) = split(/\t/, $_);
  my $lcAbbr = lc($abbr);
  $lcAbbr =~ s/\.//g;
  my $lcTitle = lc($title);
  $abbrHash{$lcAbbr} = $lcTitle;
  $jTitleHash{$lcTitle}++;
  
  $origTitleHash{$lcTitle} = $title;
}

close (T1_FILE);

open(T2_FILE, "< $biblioFile") || die "cannot open $biblioFile: $!\n";
my $bibHeaders;

while (<T2_FILE>) {
  chomp;
 
  my $line = $_;

  if ($line =~ /Publiction_ID\t(.+)/) {
    $bibHeaders = $line;
    print OUT_FILE $bibHeaders;
    print OUT_FILE "New_Journal\n";
    last;
  }
}


while (<T2_FILE>) {
  chomp;
 
  my $line = $_;

  next if ($line =~ /Publiction_ID\t(.+)/) ; 
  
  my @fields = split("\t", $line);
  my $journal_1 = $fields[6];
  
#   my ($Publiction_ID, $OLDPublication_ID, $Publication, $Publication_title, $Report_date, 
#   + $Report_Descriptions, $Journal_1, $BRC_PI_main, $Other_BRC_PI_1, $Other_BRC_PI_2,
#   + $Other_BRC_PI_3, $Other_BRC_PI_4, $Other_BRC_PI_5, $Other_BRC_PI_6, $BRC_Ack,
#   + $Should_paper_acknowledge_BRC, $Aknowldege_reason, $PI_Checked, $KHP_Author_Address,
#   + $CRF_Aknowledgement, $Publication_date, $E_Pubdate, $Theme_I, $Theme_II, $Programme,
#   + $Cluster, $Cluster_4, $Trainee_author, $Training_scheme, $Is_tranee_first_author,
#   + $Annual_Report, $RD_Board_Report) = split("\t", $line);
  
  my $journal = lc($journal_1);
  $journal =~ s/\.//g;
  
  print OUT_FILE join("\t", @fields);
  
#   print OUT_FILE $Publiction_ID, $OLDPublication_ID, $Publication, $Publication_title, $Report_date, 
#   + $Report_Descriptions, $Journal_1, $BRC_PI_main, $Other_BRC_PI_1, $Other_BRC_PI_2,
#   + $Other_BRC_PI_3, $Other_BRC_PI_4, $Other_BRC_PI_5, $Other_BRC_PI_6, $BRC_Ack,
#   + $Should_paper_acknowledge_BRC, $Aknowldege_reason, $PI_Checked, $KHP_Author_Address,
#   + $CRF_Aknowledgement, $Publication_date, $E_Pubdate, $Theme_I, $Theme_II, $Programme,
#   + $Cluster, $Cluster_4, $Trainee_author, $Training_scheme, $Is_tranee_first_author,
#   + $Annual_Report, $RD_Board_Report;
  
   if ( exists $foundAbbr{$journal} )
   {
      my $trueTitle = $foundAbbr{$journal};
      say OUT_FILE "\t", $trueTitle;
      next;
   }   
  
   if ( exists $abbrHash{$journal} )
   {
      my $newTitle = $abbrHash{$journal};
      my $trueTitle = $origTitleHash{$newTitle};
      say OUT_FILE "\t", $trueTitle;
      $foundAbbr{$journal} = $trueTitle;
      next;
   } 
   elsif ( exists $jTitleHash{$journal} )
   {
      my $trueTitle = $origTitleHash{$journal};
       say OUT_FILE "\t", $trueTitle;
       $foundAbbr{$journal} = $trueTitle;
       next;
   } else {
       say OUT_FILE "\t", "Not found: $journal";
   }
}
close (T2_FILE);
close OUT_FILE;
