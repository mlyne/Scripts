#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;
use LWP::UserAgent;
use HTTP::Date;

use feature ':5.12';

#my $base = "/SAN_synbiomine/data/";
my $base = "./";

my $contact = 'mike@intermine.org'; # Please set your email address here to help us debug in case of problems.
my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");

mkdir "$base/uniprot", 0755;
mkdir "$base/genbank", 0755;
mkdir "$base/kegg", 0755;

my $kegg_dir = $base . "kegg/";
open (KEGG_OUT, ">$kegg_dir/kegg_org.txt") or die $!;

# #&kegg_org();

my $hostname = 'ftp.ncbi.nlm.nih.gov';
my $username = 'anonymous';
my $password = 'mike@intermine.org';

# Hardcode the directory and filename we want to get
my $home = '/genomes/Bacteria';
my $file = 'summary.txt';

# Open the connection to the host
my $ftp = Net::FTP->new($hostname);        # Construct object
$ftp->login($username, $password)
  or die "Cannot login ", $ftp->message;      # Log in

$ftp->cwd($home)
 or die "Cannot change working directory ", $ftp->message;  # Change directory

my @dir_list = grep /_uid/, $ftp->ls();

my $handle = $ftp->retr($file)
  or die "get failed ", $ftp->message;

my (@keep);
my (%org_taxon, %kegg_organism, %seen_taxons);

my $genbank_dir = $base . "genbank/";

while (<$handle>) {
  chomp;
  next if ($_ =~ /GenbankAcc/); 
  my(undef, undef, undef, $taxon, $UID, $name, $type, $submission, $update) = split("\t", $_);
  if ($type =~ /chromosome/) {

    next unless ($name =~ /Bacillus|Escheric|Geobacil/);

    $name =~ s/\[//;
    $name =~ s/\]//;

# #     my $name_munge = $name;
# #     $name_munge =~ s/ substr\.//g;
# #     $name_munge =~ s/ subsp\.//g;
# #     $name_munge =~ s/ str\.//g;

    $name =~ /(\w+ \w+)/;
    my $org = $1;
    $org =~ s/ /_/g;

    my $id = "_uid$UID";

    my @id_match = grep /$id\b/, @dir_list;

    $org_taxon{$id_match[0]} = $taxon if (@id_match);
    push(@keep, @id_match) if (@id_match);

#    say "Found ID $id: ", join(" * ", @id_match) if (@id_match);

  }
}

$ftp->quit;

my $reference = 'reviewed:yes';
my $complete = 'reviewed:no';

my $db_sp = "uniprot_sprot";
my $db_tr = "uniprot_tremb";

for my $key (keys %org_taxon) {
  say "\n$org_taxon{$key}\t$key";

  my $taxon = $org_taxon{$key};
  next if ( exists $seen_taxons{$taxon} );

  mkdir "$genbank_dir$key", 0755;
  say "making: $genbank_dir$key";

# For each taxon
  say "Processing taxon: ", $taxon;

#  &query_uniprot($db_sp, $taxon, $reference);
#  &query_uniprot($db_tr, $taxon, $complete);

#  &kegg_dbget($taxon);

  $seen_taxons{$taxon}++;

}

opendir (DIR, $genbank_dir) or die "cannot open dir $genbank_dir: $!";
my @gb_dirs = grep { /_uid/ } readdir (DIR);
closedir (DIR);

my $ftp2 = Net::FTP->new($hostname);        # Construct object
$ftp2->login($username, $password)
  or die "Cannot login ", $ftp2->message;      # Log in

my $test = $gb_dirs[0];

  $ftp2->cwd("$home/$test")
    or die "Cannot change working directory ", $ftp2->message;  # Change directory

  my @file_list = grep /\.gff|\.fna/, $ftp2->ls();

  for my $gb_file (@file_list) {
    say "Adding: $genbank_dir$test/$gb_file";
    $ftp2->get($gb_file, "$genbank_dir$test/$gb_file");
  }

$ftp2->quit;

# for my $dir (@gb_dirs) {
#   say $dir;
#   $ftp->cwd($home/$dir)
#     or die "Cannot change working directory ", $ftp->message;  # Change directory
# 
#   say $ftp->ls(),
# 
# }



close (KEGG_OUT);

exit(1);

sub query_uniprot {

  my ($db, $taxon, $reference) = @_;

# Alternative formats: html | tab | xls | fasta | gff | txt | xml | rdf | list | rss
  my $file = $base . "uniprot/". $taxon . "_" . $db . '.xml';
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
#    next unless ($_ =~ /Prokaryote/);
# #     next unless ($_ =~ /Bacillus|Escheric|Geobacil/);
# #     my ($k_tax, $k_code, $org_name, $taxon) = split("\t", $_);
# # 
# #     my $name = $org_name;
# #     $name =~ s/ subsp\.//g;
# #     $name =~ s/ \(.+\)$//g;
# # 
# #     say "$k_code, $org_name: $name";
# #     $kegg_organism{$name} = $k_code;
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
    say KEGG_OUT $tla;
  }

}

sub kegg_org {

  my $url = "http://rest.kegg.jp/list/organism";

  my $request  = HTTP::Request->new(GET => $url);
  my $response = $agent->request($request);

  $response->is_success or say "Error: " . 
  $response->code . " " . $response->message;

  my $content = $response->content;
  #say $content;

  open my ($str_fh), '+<', \$content;

  while (<$str_fh>) {
    chomp;
#    next unless ($_ =~ /Prokaryote/);
    next unless ($_ =~ /Bacillus|Escheric|Geobacil/);
    my ($k_tax, $k_code, $org_name, $taxon) = split("\t", $_);

    my $name = $org_name;
    $name =~ s/ subsp\.//g;
    $name =~ s/ \(.+\)$//g;

    say "$k_code, $org_name: $name";
    $kegg_organism{$name} = $k_code;
  }

  close ($str_fh);

}


