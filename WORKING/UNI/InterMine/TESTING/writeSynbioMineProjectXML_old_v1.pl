#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;

use feature ':5.12';

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:writeSynbioMineProjectXML.pl [-t | -v | -h] genbank_directory\n
options:
\t-h\tusage
\t-t\tprint details in tab view
\t-v\tverbose mode - additional output for debugging
";

my (%opts, $tabView, $verbose);

getopts('htv', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $tabView++;
defined $opts{"v"} and $verbose++;

my $dir = ($ARGV[0]) ? "$ARGV[0]" : '/micklem/data/ecolimine/genbank/current';
# my $dir = '/SAN_synbiomine/data/genbank/current';

opendir(DIR, $dir) or die "cannot open dir: $!";

say "taxID\ttaxname\tsubdir\tNCid" if ($tabView);

while (my $subdir = readdir DIR) {
  my $gbDir = "$dir/$subdir";

  next if $subdir =~ /\.|\.\./;

  $subdir =~ /^(.+)_uid\d+/;
  my $orgm = $1;
  $orgm =~ s/_/-/g;

  opendir(CURR, $gbDir) or die "cannot open dir: $!";
  my %gffSize;

  my @gff = grep( /\.gff$/, readdir (CURR) );

  if ( @gff ) {
    foreach my $file (@gff) {
      my $fSize = -s "$gbDir/$file";
      $file =~ /^(NC_\d+).gff/;
      my $ncID = $1;
      $gffSize{$ncID} = $fSize;
    }
  }

  my @keys = sort { $gffSize{$b} <=> $gffSize{$a} } keys %gffSize;
  my $largest = $keys[0];
  say $largest if ($verbose);

  my $asn = "$largest\.asn";

  open ASN_IN, "$gbDir/$asn" or die "can't open file: $!";

  my ($taxname, $taxID);
  while (<ASN_IN>) {

    if ($_ =~ /taxname/) {
    $_ =~ /^\s+taxname \"(.+)\"/;
    $taxname = "$1";
    }

    if ($_ =~ /tag id/) {
      $_ =~ /^\s+tag id (.+)$/;
      $taxID = $1;
      last;
    }
  }

  close (ASN_IN);

  if ($tabView) {
    say $taxID, "\t", $taxname, "\t", $subdir, "\t", $largest;
    next;
  }

  say "TAX:$taxname, $taxID" if ($verbose);

  my $gffFile = "$largest\.gff";
  my $chrm = "$largest\.fna";
  my $fasta = "$largest\.frn";

  if (-e "$gbDir/$gffFile") {
    say $gffFile if ($verbose);
    &gff_print($orgm, $taxID, $taxname, $subdir, $gbDir, $gffFile);
  }

  if (-e "$gbDir/$chrm") {
    say $chrm if ($verbose);
    &chrm_print($orgm, $taxID, $taxname, $chrm, $gbDir);
  }

  if (-e "$gbDir/$fasta") {
    say $fasta if ($verbose);
    &fasta_print($orgm, $taxID, $taxname, $fasta, $gbDir);
  }
  
closedir(CURR);
}

closedir(DIR);
exit 0;

sub gff_print {
  my ($orgm, $taxID, $taxname, $subdir, $gbDir, $gffFile) = @_;

  my $gff_block = <<EOF;
    <source name="$orgm-gff" type="gff">
      <property name="gff3.taxonId" value="$taxID"/>
      <property name="gff3.seqDataSourceName" value="NCBI"/>
      <property name="gff3.dataSourceName" value="NCBI"/>
      <property name="gff3.seqClsName" value="Chromosome"/>
      <property name="gff3.dataSetTitle" value="$taxname genomic features"/>
      <property name="src.data.dir" location="$gbDir/"/>
      <property name="src.data.dir.includes" value="$gffFile"/>
    </source>
EOF
 say $gff_block, "\n" unless $tabView;
}

sub chrm_print {
  my ($orgm, $taxID, $taxname, $chrm, $gbDir) = @_;

  my $chrm_block = <<EOF;
    <source name="$orgm-chromosome-fasta" type="fasta">
      <property name="fasta.taxonId" value="$taxID"/>
      <property name="fasta.className" value="org.intermine.model.bio.Chromosome"/>
      <property name="fasta.dataSourceName" value="GenBank"/>
      <property name="fasta.dataSetTitle" value="$taxname chromosome, complete genome"/>
      <property name="fasta.includes" value="$chrm"/>
      <property name="fasta.classAttribute" value="primaryIdentifier"/>
      <property name="src.data.dir" location="$gbDir/"/>
      <property name="fasta.loaderClassName"
                value="org.intermine.bio.dataconversion.NCBIFastaLoaderTask"/>   
    </source>
EOF
 say $chrm_block unless ($tabView);
}

sub fasta_print {
  my ($orgm, $taxID, $taxname, $fasta, $gbDir) = @_;

  my $fasta_block = <<EOF;
    <source name="$orgm-gene-fasta" type="fasta">
      <property name="fasta.taxonId" value="$taxID"/>
      <property name="fasta.dataSetTitle" value="$taxname fasta data set for genes"/>
      <property name="fasta.dataSourceName" value="NCBI"/>
      <property name="fasta.className" value="org.intermine.model.bio.Gene"/>
      <property name="fasta.classAttribute" value="primaryIdentifier"/>
      <property name="fasta.includes" value="$fasta"/>
      <property name="src.data.dir" location="$gbDir/"/>
    </source>
EOF
 say $fasta_block unless ($tabView);
}
