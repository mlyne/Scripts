#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;
#use Net::FTP::AutoReconnect;
use LWP::UserAgent;
use HTTP::Date;
use Time::localtime;

use IO::Uncompress::Gunzip qw(:all);

use feature ':5.12';

# date settings
my $tm = localtime;
my ($DAY, $MONTH, $YEAR) = ($tm->mday, ($tm->mon)+1, ($tm->year)+1900);

#my $base = "/SAN_synbiomine/data/";

my $base = ($ARGV[0]) ? ($ARGV[0]) : "./";
#my $base = "./";
my $date_dir  = $DAY . "_" . $MONTH . "_" . $YEAR;

my $contact = 'mike@intermine.org'; # Please set your email address here to help us debug in case of problems.
my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");

mkdir $base . "uniprot/$date_dir", 0755 or die "Couldn't make dir:$base uniprot/$date_dir. Check that $base uniprot exists\n";
mkdir $base . "genbank/$date_dir", 0755 or die "Couldn't make dir:$base genbank/$date_dir. Check that $base genbank exists\n";
mkdir $base . "kegg/$date_dir", 0755 or die "Couldn't make dir:$base kegg/$date_dir. Check that $base kegg exists\n";
mkdir $base . "taxons/$date_dir", 0755 or die "Couldn't make dir:$base taxons/$date_dir. Check that $base taxons exists\n";

my $hostname = 'ftp.ncbi.nlm.nih.gov';
my $timeout      = 600;     # seconds, default is 120
#my $retries      = 5;
my $username = 'anonymous';
my $password = 'mike@intermine.org';

# Hardcode the directory and filename we want to get
my $home = '/genomes/ASSEMBLY_REPORTS';
my $file = 'assembly_summary_refseq.txt';
my $refseq = '/genomes/refseq/archaea';

# Open the connection to the host
my $ftp = Net::FTP->new($hostname, BlockSize => 20480, Timeout => $timeout, Debug   => 1);        # Construct object
$ftp->login($username, $password)
  or die "Cannot login ", $ftp->message;      # Log in

$ftp->cwd($home)
 or die "Cannot change working directory ", $ftp->message;  # Change directory

#my @dir_list = grep /_uid/, $ftp->ls();

my $handle = $ftp->retr($file)
  or die "get failed ", $ftp->message;

my (@keep);
my (%org_taxon, %kegg_organism, %seen_taxons);

my $genbank_dir = $base . "genbank";

my @assem = grep /Pyrolobus|Thermoproteus|Thermococcus|Methanosarcina/, <$handle>;
### my @assem = grep / subtilis/, <$handle>; # quick version for testing

close ($handle);
$ftp->quit;

my @genomes;
#while (<$handle>) {
for (@assem) {
  chomp;
#  next if ($_ =~ /wgs_master/);

#  say "Trying: ", $_; 

#  next unless ($_ =~ /reference-genome|representative-genome/); # they changed the format!
# they used to use -, now they use space - 'genome' seems to catch what we need but this may change too!
# Now test on $refseq_category

#  next unless ($_ =~ /-genome| genome/);
  my($assembly_id, $bioproject, $biosample, $wgs_master, $refseq_category, $taxid, 
    $species_taxid, $organism_name, $infraspecific_name, $isolate, $version_status, 
    $assembly_level, $release_type, $genome_rep, $seq_rel_date, $asm_name, 
    $submitter, $gbrs_paired_asm, $paired_asm_comp) = split("\t", $_);

  next unless ( ($refseq_category) && ($refseq_category =~ /-genome| genome/));

  $organism_name =~ s/\[/_/;
  $organism_name =~ s/\]//;

  if ($assembly_level =~ /Chromosome/) {

    say $_;

    my $assembly_vers = $assembly_id . "_" . $asm_name;
    my $assembly_dir = "all_assembly_versions/" . $assembly_vers;

    my $species;
    if ($organism_name =~ / sp\. /) {
      $organism_name =~ /(.+)/;
      $species = $1;
    }
    else {
      $organism_name =~ /(\w+ \w+)/;
      $species = $1;
    }

    $species =~ s/ /_/g;

    if ( exists $org_taxon{$taxid} ) {
      if ( ($taxid eq '224308') and ($refseq_category =~ /reference-genome/) ) {
	next;
      }
      elsif ($refseq_category =~ /representative-genome/) {
	next;
      }
    }

    $org_taxon{$taxid} = [$species, $assembly_vers, $refseq_category, $assembly_dir]; 

  }
}

# Process NCBI genomes
my $ftp2 = Net::FTP->new($hostname, BlockSize => 20480, Timeout => $timeout, Debug   => 0);        # Construct object
$ftp2->login($username, $password)
  or die "Cannot login ", $ftp2->message;      # Log in

for my $key (keys %org_taxon) {

  my ($species, $assembly_vers, $refseq_category, $assembly_dir) = @{ $org_taxon{$key} };
  mkdir "$genbank_dir/$date_dir/$assembly_vers", 0755;

  my $refseq_path = $refseq . "/" . $species . "/" . $assembly_dir;
  say "Trying FTP for: $refseq_path";

  $ftp2->cwd("$refseq/$species/$assembly_dir")
    or die "Cannot change working directory ", $ftp2->message;  # Change directory

  my @file_list = grep /\.gff.gz|\.fna.gz|_report.txt/, $ftp2->ls();

  for my $gb_file (@file_list) {
    say "Processing FILE: ", $gb_file;

    if ($gb_file =~ /\.gz/) {
      $gb_file =~ /(.+)\.gz/;
      my $raw = $1;

      $ftp2->binary or die "Cannot set binary mode: $!";
      say "Fetch and unzip: $gb_file --> $raw";

      my $retr_fh = $ftp2->retr($gb_file) or warn "Problem with $refseq_path\nCannot retrieve $gb_file\n";

      if ($retr_fh) {
	gunzip $retr_fh => "$genbank_dir/$date_dir/$assembly_vers/$raw", AutoClose => 1
	  or warn "Zip error $refseq_path\nCannot uncompress '$gb_file': $GunzipError\n";
	say "Success - adding: $genbank_dir/$date_dir/$assembly_vers/$raw";
      }
      else {
	say "Darn! Problem with $refseq_path\nCouldn't get $gb_file";
	next;
      }
    }
    else {
      $ftp2->ascii or die "Cannot set ascii mode: $!";
      say "Fetching: $gb_file";
      $ftp2->get($gb_file, "$genbank_dir/$date_dir/$assembly_vers/$gb_file")
	or warn "Problem with $refseq_path\n\nCannot retrieve $gb_file\n";
    }
  }
}

$ftp2->quit;

# process KEGG and UniProt
my $kegg_dir = $base . "kegg/$date_dir";
open (KEGG_ORG_OUT, ">$kegg_dir/kegg_org.txt") or die "Can't write file: $kegg_dir/kegg_org.txt: $!\n";
open (KEGG_TAXA_OUT, ">$kegg_dir/kegg_taxa.txt") or die "Can't write file: $kegg_dir/kegg_taxa.txt: $!\n";

my $taxon_dir = $base . "taxons/$date_dir";
open (TAXON_OUT, ">$taxon_dir/taxons_$date_dir.txt") or die "Can't write file: $taxon_dir/taxons_$date_dir.txt: $!\n";

my $reference = 'reviewed:yes';
my $complete = 'reviewed:no';

my $db_sp = "uniprot_sprot";
my $db_tr = "uniprot_tremb";

# Add reference proteomes - not real strains so no genome sequence
#$org_taxon{"83333"} = ["reference model 83333 - no genome sequence"];
#$org_taxon{"1392"} = ["reference model 1392 - no genome sequence"];

my @taxa;
for my $key (keys %org_taxon) {
  say "\n$key: ", join(" * ", @{ $org_taxon{$key} } );

  my $taxon = $key;
  push (@taxa, $taxon);

# For each taxon
  say "Processing taxon: ", $taxon;

  &kegg_dbget($taxon);

  &query_uniprot($db_sp, $taxon, $reference);
  &query_uniprot($db_tr, $taxon, $complete);

}

say TAXON_OUT join(" ", @taxa);

close (KEGG_ORG_OUT);
close (KEGG_TAXA_OUT);
close (TAXON_OUT);

exit(1);

sub query_uniprot {

  my ($db, $taxon, $reference) = @_;

# Alternative formats: html | tab | xls | fasta | gff | txt | xml | rdf | list | rss
  my $file = $base . "uniprot/$date_dir/". $taxon . "_" . $db . '.xml';
  my $query_taxon = "http://www.uniprot.org/uniprot/?query=organism:$taxon+$reference&format=xml&include=yes";

  my $response_taxon = $agent->mirror($query_taxon, $file);

  if ($response_taxon->is_success) {

    my $results = $response_taxon->header('X-Total-Results');
    unless ($results) {
      if ($db =~ /sprot/) {
	say "No SwissProt results for $taxon";
	unlink $file;
	return;
      }
      else {
	say "No TrEMBL results for $taxon\n";
	unlink $file;
	return;
      }
    }

    my $release = $response_taxon->header('X-UniProt-Release');
    my $date = sprintf("%4d-%02d-%02d", HTTP::Date::parse_date($response_taxon->header('Last-Modified')));
    say "Success for Taxon: $taxon with $db";
    say "File $file: downloaded $results entries of UniProt release $release ($date)";
    say "\n";
    return;
  }
  elsif ($response_taxon->code == HTTP::Status::RC_NOT_MODIFIED) {
    say "File $file: up-to-date";
  }
  else {
    warn 'Failed, got ' . $response_taxon->status_line .
      ' for ' . $response_taxon->request->uri . "\n";
  }
  return;
}


sub kegg_dbget {

  my $taxon = shift;

  my $url = "http://www.genome.jp/dbget-bin/www_bfind_sub?dbkey=genome&keywords=$taxon&mode=bfind&max_hit=5";
## "http://rest.kegg.jp/list/organism";
## http://www.genome.jp/dbget-bin/www_bfind_sub?dbkey=genome&keywords=$taxon&mode=bfind&max_hit=5

  my $request  = HTTP::Request->new(GET => $url);
  my $response = $agent->request($request);

  $response->is_success or say "Error: " . 
  $response->code . " " . $response->message;

  my $content = $response->content;
  #say $content;

  open my ($str_fh), '+<', \$content;

  my @elements;
  while (<$str_fh>) {
    chomp;

    if ($_ =~ /www_bget\?genome/) {
      @elements = split("\>", $_);
    }
  }

  close ($str_fh);

  my @matches = grep /$taxon\;/, @elements;

#      say $_;
  if (@matches) {
    my $kegg_info = $matches[0];

    $kegg_info =~ s/^ //g;
    $kegg_info =~ s/\<.+//g;
    $kegg_info =~ s/\;/,/;

    my ($tla, $uniprot, $kegg_taxon, $org_name) = split(", ", $kegg_info);
    unless ($uniprot =~ /[A-Z]/) {
      $org_name = $kegg_taxon;
      $kegg_taxon = $uniprot;
    }
    $org_name =~ s/ \(.+\)$//g;

    say "info: $kegg_info";
    say "out: $tla, $kegg_taxon, $org_name";
    say KEGG_ORG_OUT $tla;
    say KEGG_TAXA_OUT $tla . ".taxonId = " . $kegg_taxon;
  }

}

# # sub ftp_genomes {
# # 
# #   my ($refseq, $species, $assembly_dir, $ftp_connect) = @_;
# # 
# #   $ftp_connect->cwd("$refseq/$species/$assembly_dir")
# #     or die "Cannot change working directory ", $ftp_connect->message;  # Change directory
# # 
# #   my @file_list = grep /\.gff.gz|\.fna.gz/, $ftp_connect->ls();
# # 
# #   for my $gb_file (@file_list) {
# #     $gb_file =~ /(.+)\.gz/;
# #     my $raw = $1;
# # 
# #     say "Fetch and unzip: $gb_file --> $raw";
# #     my $retr_fh = $ftp_connect->retr($gb_file) or warn "Problem with $refseq_path\nCannot retrieve $gb_file\n";
# #   
# #     if ($retr_fh) {
# #       gunzip $retr_fh => "$genbank_dir/$date_dir/$assembly_vers/$raw", AutoClose => 1
# #         or warn "Zip error $refseq_path\nCannot uncompress '$gb_file': $GunzipError\n";
# #       next;
# #     }
# #     else {
# #       return;
# #     }
# #   }
# # }

# # sub kegg_org {
# # 
# #   my $url = "http://rest.kegg.jp/list/organism";
# # 
# #   my $request  = HTTP::Request->new(GET => $url);
# #   my $response = $agent->request($request);
# # 
# #   $response->is_success or say "Error: " . 
# #   $response->code . " " . $response->message;
# # 
# #   my $content = $response->content;
# #   #say $content;
# # 
# #   open my ($str_fh), '+<', \$content;
# # 
# #   while (<$str_fh>) {
# #     chomp;
# # #    next unless ($_ =~ /Prokaryote/);
# #     next unless ($_ =~ /Bacillus|Escheric|Geobacil/);
# #     my ($k_tax, $k_code, $org_name, $taxon) = split("\t", $_);
# # 
# #     my $name = $org_name;
# #     $name =~ s/ subsp\.//g;
# #     $name =~ s/ \(.+\)$//g;
# # 
# #     say "$k_code, $org_name: $name";
# #     $kegg_organism{$name} = $k_code;
# #   }
# # 
# #   close ($str_fh);
# # 
# # }


