#!/usr/local/bin/perl -w
#
#
#


use strict;

my $usage = "Usage:LG_id2description.pl pattern_file " .
    "Representative_template_file\n";

unless ( $ARGV[1] ) { die $usage }

my $pattern_list = $ARGV[0];
my $template_file = $ARGV[1];

$| = 1;

open(PATTERN, "< $pattern_list") || die "cannot open $pattern_list: $!\n";

my $id_line;
my @grep_results;
my $grep_result;
my $template_id;
my $genbank_id;
my $description;

READ_LOOP:while (<PATTERN>)
{
  chomp;
  $id_line = "LG:$_\\.";
  @grep_results = `grep "$id_line" $template_file`;
   $grep_result = shift(@grep_results);

   if ($grep_result)
   {
     if ($grep_result =~ /^(LG:.+)\n/)
     {
       $template_id = $1;
#       print "$template_id\n";
     }
   }
   else
   {
     print "$id_line\tpattern not found\n";
     next READ_LOOP;
   }

   $genbank_id = retrieve_gbid($template_id) || "no data";

   if ($genbank_id eq "no data")
   {
     print "$template_id\tNot in Genbank\tNot in Genbank\n";
     next READ_LOOP;
   }

   $description = efetch_de($genbank_id) || "no data";

   print "$template_id\t$genbank_id\t$description\n";

 }

###             ###
### Subroutines ###
###             ###

sub retrieve_gbid
{

  my ($id) = @_;
  my @blast_results;
  my $blast_result;
  my @data;
  my $gb_id;

  open(RETRIEVE, "echo $template_id | lt_retrieve /d2/databases/incyte/Gold" .
       " | blastall -p blastn -d \"hum_rna hum_rna_new\" -i stdin | " . 
       "MSPcrunch -d -I 50 - | " . 
       "sort -nr |") || die "Couldn't fork: $!\n";

  while (<RETRIEVE>)
  {
    chomp;
    push( @blast_results, $_ );
  }

  close(RETRIEVE) || die "Couldn't close fork: $!\n";

  unless (@blast_results) {
    $gb_id = "";
    return $gb_id;
  }

  $blast_result = shift(@blast_results);

  @data = split(/\s+/, $blast_result);
  $gb_id = $data[-2];

  return $gb_id;
}

sub efetch_de
{
  my ($gb_id) = @_;
  my $de_line;

  open(EFETCH, "echo $gb_id | efetch | grep '^DE' |") 
       || die "Couldn't fork: $!\n";

  while (<EFETCH>)
  {
    chomp;
    s/DEFINITION\s+//;
    $de_line = $_;
  }

  return $de_line;

}
