#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;

use feature ':5.12';

my $hostname = 'ftp.ncbi.nlm.nih.gov';
my $username = 'anonymous';
my $password = 'mike@intermine.org';

# Hardcode the directory and filename to get
my $home = '/genomes/Bacteria';
my $file = 'summary.txt';

# Open the connection to the host
my $ftp = Net::FTP->new($hostname);        # Construct object
$ftp->login($username, $password)
  or die "Cannot login ", $ftp->message;      # Log in

$ftp->cwd($home)
 or die "Cannot change working directory ", $ftp->message;  # Change directory

my @dir_list = grep /_uid/, $ftp->ls();
# my @dir_list = $ftp->ls();

my $handle = $ftp->retr($file)
  or die "get failed ", $ftp->message;

# $ftp->quit;

my (@keep);
my %org_taxon;

while (<$handle>) {
  chomp;
  next if ($_ =~ /GenbankAcc/); 
  my(undef, undef, undef, $taxon, $UID, $name, $type, $submission, $update) = split("\t", $_);
  if ($type =~ /chromosome/) {

    next unless ($name =~ /Bacillus|Escheric|Geobacil/);

    $name =~ s/\[//;
    $name =~ s/\]//;

    $name =~ /(\w+ \w+)/;
    my $org = $1;
    $org =~ s/ /_/g;

    my $id = "_uid$UID";

#    my @org_match = grep /$org/, @dir_list;
#    push(@keep, @org_match) if (@org_match);

    my @id_match = grep /$id\b/, @dir_list;

    $org_taxon{$id_match[0]} = $taxon if (@id_match);
    push(@keep, @id_match) if (@id_match);

#    say "Found ID $id: ", join(" * ", @id_match) if (@id_match);

  }
}

$ftp->quit;

for my $key (keys %org_taxon) {
  say "$org_taxon{$key}\t$key";
}

# # my %seen;
# # my @uniqs = grep { !$seen{$_}++ } @keep;

# for my $bact (@uniqs) {
# #  if ($bact =~ /Bacillus|Escheric|Geobacil/) {
# #    say $bact;
# #  }
# }

exit(1);
