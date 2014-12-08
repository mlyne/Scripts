#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;

use feature ':5.12';

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:writeSynbioMineProjectXML.pl [-tvgh] genbank_directory\n
options:
\t-h\tthis usage
\t-t\tprint details in tab view
taxID\ttaxname\tsubdir\tNCid\n
\t-g\twrite gff_config file 
\t-v\tverbose mode - additional output for debugging
";

my (%opts, $tabView, $gffconfig, $verbose);

getopts('htgv', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $tabView++;
defined $opts{"g"} and $gffconfig++;
defined $opts{"v"} and $verbose++;

my $dir = ($ARGV[0]) ? "$ARGV[0]" : '/micklem/data/ecolimine/genbank/current';
# my $dir = '/SAN_synbiomine/data/genbank/current';

if ($gffconfig) {
  open (GFF_CONF_OUT, ">./gff_config.txt") or die "Can't write file: ./gff_config.txt: $!\n";
  say "Writing ./gff_config.txt";
}

opendir(DIR, $dir) or die "cannot open dir: $!";

say "taxID\ttaxname\tsubdir\tNCid" if ($tabView);
#say GFF_CONF_OUT "taxID: taxname\talt ID\tlocus_tag\tsymbol\tsynonym" if ($gffconfig);

while (my $subdir = readdir DIR) {
  my $gbDir = "$dir/$subdir";

  next if $subdir =~ /^\.|^\.\./;
  say "SUB: ", $subdir if ($verbose);

  opendir(CURR, $gbDir) or die "cannot open dir: $!";
  my %gffSize;

  my @list = readdir (CURR);

  my @gff = grep( /gff/, @list );
  my @report = grep( /txt/, @list );

  if ( @gff ) {
    foreach my $file (@gff) {
      my $fSize = -s "$gbDir/$file";
      $file =~ /^(.+)\.gff/;
      my $ncID = $1;
      $gffSize{$ncID} = $fSize;
    }
  }

  my @keys = sort { $gffSize{$b} <=> $gffSize{$a} } keys %gffSize;
  my $largest = $keys[0];
  say $largest if ($verbose);

  my $report = $report[0];
#  say $report;

  open REPORT_IN, "$gbDir/$report" or die "can't open file: $!";

  my ($taxname, $taxID, $orgm);
  while (<REPORT_IN>) {
    chomp;
# Organism name:  Bacillus anthracis str. Ames
# Taxid:          198094

    if ($_ =~ /Organism name/) {
      $_ =~ /Organism name:\s+(.+)/;
      $taxname = $1;
      $taxname =~ s/\[//;
      $taxname =~ s/\]//;

      $orgm = $taxname;
      $orgm =~ s/ /-/g;
      $orgm =~ s/\.//g;
    }

    if ($_ =~ /Taxid/) {
      $_ =~ /Taxid:\s+(\d+)/;
      $taxID = $1;
      last;
    }
  }

  close (REPORT_IN);

#### working

  my $gffFile = "$largest\.gff";

  if ($gffconfig) {
    open GFF_IN, "$gbDir/$gffFile" or die "can't open file $gffFile: $!";

    my @gff_line;
    my ($annotation, $db_Xref, $alt_id, $locus_tag, $symbol, $synonym);
    while (<GFF_IN>) {
      chomp;
  # Organism name:  Bacillus anthracis str. Ames
  # Taxid:          198094
  # ID=gene0;Dbxref=EcoGene:EG11277,GeneID:944742;Name=thrL;gbkey=Gene;gene=thrL;gene_synonym=ECK0001,JW4367;locus_tag=b0001
  # ID=gene0;Dbxref=GeneID:939978;Name=dnaA;gbkey=Gene;gene=dnaA;locus_tag=BSU00010
      if ($_ =~ /ID=gene0\;/) {
	@gff_line = split("\t", $_);
	$annotation = $gff_line[-1];

	($db_Xref = $1) if ($annotation =~ /.+;Dbxref=(.+?),/);
	($alt_id = $1) if ($db_Xref =~ /(.+):/);
	($symbol = $1) if ($annotation =~ /;gene=(.+?)\;/);
	($synonym = $1) if ($annotation =~ /;gene_synonym=(.+)\;/);

	($locus_tag = $1) if ($annotation =~ /.+;locus_tag=(.+)/);
	$locus_tag =~ s/;old_locus_tag=.+$// if ($locus_tag);

	if ($locus_tag) {
	  say GFF_CONF_OUT "$taxID.terms=gene,CDS";
	  if ($alt_id) {
#	    say GFF_CONF_OUT "$taxID.gene.attributes.Dbxref.$alt_id=primaryIdentifier\n",
#	      "$taxID.gene.attributes.locus_tag=secondaryIdentifier";
	  }
	  else {
#	    say GFF_CONF_OUT "$taxID.gene.attributes.locus_tag=primaryIdentifier";
	  }
	  if ($symbol) {
#	    say GFF_CONF_OUT "$taxID.gene.attributes.gene=symbol";
	  }
	  if ($synonym) {
#	    say GFF_CONF_OUT "$taxID.gene.attributes.gene_synonym=synonym";
	  }
#	  say GFF_CONF_OUT "$taxID.CDS.attributes.Name=primaryIdentifier";
#	  say GFF_CONF_OUT "$taxID.exon.attributes.type=scoreType";
	  say GFF_CONF_OUT "";
#	  say GFF_CONF_OUT "$taxID: $taxname\t$alt_id\t$locus_tag\t$symbol\t$synonym";
	}
	
  # #       ($chrm, undef, undef, undef, undef, 
  # # 	undef, undef, undef, $annotation) = split("\t", $_);
	last;
      }
    }

    close (GFF_IN);

  }

####

  if ($tabView) {
    say "$taxID\t$taxname\t$subdir\t$largest";
    next;
  }

  say "TAX:$taxname, $taxID" if ($verbose);

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
#    &fasta_print($orgm, $taxID, $taxname, $fasta, $gbDir);
  }
  
closedir(CURR);
}

close (GFF_CONF_OUT) if ($gffconfig);

closedir(DIR);
exit 0;

sub gff_print {
  my ($orgm, $taxID, $taxname, $subdir, $gbDir, $gffFile) = @_;

  my $gff_block = <<EOF;
    <source name="$orgm-gff" type="synbio-gff">
      <property name="gff3.taxonId" value="$taxID"/>
      <property name="gff3.seqDataSourceName" value="NCBI"/>
      <property name="gff3.dataSourceName" value="NCBI"/>
      <property name="gff3.seqClsName" value="Chromosome"/>
      <property name="gff3.dataSetTitle" value="$taxname genomic features"/>
      <property name="src.data.dir" location="$gbDir/"/>
      <property name="src.data.dir.includes" value="$gffFile"/>
    </source>
EOF
 say $gff_block, unless ($tabView or $gffconfig);
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
 say $chrm_block unless ($tabView or $gffconfig);
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
 say $fasta_block unless ($tabView or $gffconfig);
}
