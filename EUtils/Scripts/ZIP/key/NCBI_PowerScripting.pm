#!/usr/bin/perl 
#E-utility Perl module
#NCBI PowerScripting
#EW Sayers 
#version 1.1, 10/26/04: added sub link_history, deleted link_post
#version 1.2, 1/21/05: revised esummary and print_summary to handle homologene docsum XML
#version 1.2.1 3/1/05: added WebEnv as input parameter in EPost routines
#version 1.3 3/2/05: added sub elink_batch
#version 1.4 4/8/05: added sub elink_by_id
#version 1.5 7/11/05: added sub get_uids; esummary returns XML by default; corrected elink
# output when no links are found
#version 1.6 8/8/05: added efetch_links_by_id, esummary_links_by_id, and added get_uids parameter to elink_by_id
#version 1.61 8/10/05: altered elink_by_id to produce index files; removed efetch_links_by_id and esummary_links_by_id
#version 1.7 9/20/05: altered esearch to use POST method

# ===========================================================================
#
#                            PUBLIC DOMAIN NOTICE
#               National Center for Biotechnology Information
#
#  This software/database is a "United States Government Work" under the
#  terms of the United States Copyright Act.  It was written as part of
#  the author's official duties as a United States Government employee and
#  thus cannot be copyrighted.  This software/database is freely available
#  to the public for use. The National Library of Medicine and the U.S.
#  Government have not placed any restriction on its use or reproduction.
#
#  Although all reasonable efforts have been taken to ensure the accuracy
#  and reliability of the software and data, the NLM and the U.S.
#  Government do not and cannot warrant the performance or results that
#  may be obtained by using this software or data. The NLM and the U.S.
#  Government disclaim all warranties, express or implied, including
#  warranties of performance, merchantability or fitness for any particular
#  purpose.
#
#  Please cite the author in any work or product based on this material.
#
# ===========================================================================
#
# Author:  Eric W. Sayers  sayers@ncbi.nlm.nih.gov
# http://www.ncbi.nlm.nih.gov/Class/PowerTools/eutils/course.html
#
#  
# ---------------------------------------------------------------------------


#Contains the following subroutines:
#read_params
#egquery
#esearch
#esearch_links
#esummary
#esummary_links_by_id
#efetch
#efetch_batch
#efetch_links_by_id
#elink
#elink_history
#elink_batch
#elink_by_id
#epost_uids
#epost_file
#epost_set
#print_summary
#print_links
#print_link_summaries
#get_uids
#read_index

package NCBI_PowerScripting;
use LWP::Simple;
use LWP::UserAgent;
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK);
use Exporter;
use Data::Dumper;

@ISA = qw (Exporter);
@EXPORT = qw (read_params egquery esearch esearch_links esummary efetch efetch_batch elink
                 epost_uids epost_file elink_history elink_batch elink_by_id 
		 epost_set print_summary print_links print_link_summaries get_uids read_index );
		 
$VERSION = '1.7';

my $delay = 0;
my $maxdelay = 3;

#*************************************************************

sub read_params {

# Reads input parameters from file supplied on command line
# Input file must have lines of the following format:
#   parameter|value
# where parameter is the URL parameter name and value is the
# value to be assigned to parameter
# For ELink, the parameter "dbfrom" must be on a line before 
# the id parameters. This allows multiple &id parameters
# Input: file named on command line
# Output: %params; keys are parameter names, values are values
# Example: $params{'db'} = 'nucleotide'
# $params{'id'} is an array if "dbfrom" parameter is in input file

my ($param, $value);
my (@keys, @test);
my %params;
my %mark;
my $dbfrom;

#check for correct command line syntax
if ($#ARGV != 0) { die "Usage: [eutil].pl input_file\n"; }

#read input parameter file
open(INPUT, "<$ARGV[0]") || die "Aborting. Can't open $ARGV[0]\n";

while (<INPUT>) {

   chomp;
   ($param, $value) = split(/\|/);
   if ($param eq 'dbfrom') { $dbfrom = 1; }
   if (($param eq 'id') && ($dbfrom)) {
      push (@{$params{$param}}, $value);
   }
   else {
      $params{$param} = $value;
   }
}

close INPUT;

return (%params);

}

#************************************************************************

sub egquery {

# Performs EGQuery.
# Input: %params:
# $params{'term'} - Entrez query
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
# Output = %results; keys are databases, values are UID counts

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);
my @out;
my $database;
my %results;
my ($begin, $end);

sleep($delay);

$url = $base . "egquery.fcgi?term=$params{'term'}";
$url .= "&tool=$params{'tool'}&email=$params{'email'}";

print "\n$url\n\n" if ($params{'verbose'});

$begin = time;
$raw = get($url);

@out = split(/^/, $raw);

foreach (@out) {

   if (/<DbName>(.*)<\/DbName>/) { $database = $1; }
   if (/<Count>(\d+)<\/Count>/) { $results{$database} = $1; }

}

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return(%results);

}

#*********************************************************************

sub esearch {

# Performs ESearch. 
# Input: %params
# $params{'db'} - database
# $params{'term'} - Entrez query
# $params{'usehistory'} (y/n) - flag for using the Entrez history server
# $params{'retstart'} - first item in results list to display (default = 0)
# $params{'retmax'} - number of items in results list to display (default = 20)
# $params{'WebEnv'} - Web Environment for accessing existing data sets
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: %results: keys are 'count', 'query_key', 'WebEnv', 'uids'
# $results{'uids'} is an array

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $url_params, $raw, $raw_cont);
my @out;
my %results;
my ($begin, $end);

sleep($delay);

$url_params = "db=$params{'db'}&term=$params{'term'}";
$url_params .= "&usehistory=$params{'usehistory'}&WebEnv=$params{'WebEnv'}";
$url_params .= "&retstart=$params{'retstart'}&retmax=$params{'retmax'}";
$url_params .= "&tool=$params{'tool'}&email=$params{'email'}";

$url = $base . "esearch.fcgi";

#create user agent
my $ua = new LWP::UserAgent;
$ua->agent("esearch/1.0 " . $ua->agent);

#create HTTP request object
my $req = new HTTP::Request POST => "$url";
$req->content_type('application/x-www-form-urlencoded');
$req->content("$url_params");

$begin = time;
#post the HTTP request
$raw = $ua->request($req);

print "\n$url?$url_params\n\n" if ($params{'verbose'});

$raw_cont = $raw->content;

$raw_cont =~ /<Count>(\d+)<\/Count>/s;
$results{'count'} = $1; 
$raw_cont =~ /<QueryKey>(\d+)<\/QueryKey>.*<WebEnv>(\S+)<\/WebEnv>/s;
$results{'query_key'} = $1 if ($params{'usehistory'} eq 'y');
$results{'WebEnv'} = $2;
@out = split(/^/, $raw_cont);

foreach (@out) {
   if (/<Id>(\d+)<\/Id>/) { push (@{$results{'uids'}}, $1); }
}   

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

if ($results{'count'} == 0) { 
   print "ALERT: ESearch found no records for this query:\n";
   print "$params{'term'}\n";
}

return(%results);

}

#****************************************************************

sub esearch_links {

# Performs ESearch on the output of elink_by_id ONLY
# Input: %params:
# $params{'db'} - database
# $params{'term'} - Entrez query
# $params{'usehistory'} (set to y) - flag for using the Entrez history server
# $params{'retstart'} - first item in results list to display (default = 0)
# $params{'retmax'} - number of items in results list to display (default = 20)
# $params{'WebEnv'} - Web Environment for accessing existing data sets
# $params{'infile'} - index file (.idx) produced by elink_by_id
# $params{'outfile'} - index file (.idx) containing results of esearch for each UID
# 	default = infile_search.idx
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: one hash and one file:
# %results: keys are 'count', 'query_key', 'WebEnv', 'uids'
#   $results{'uids'} is an array
# outfile.idx - index file containing lines of the form
#   input UID in dbfrom:linked UIDs in db (comma-delimited list)

my %params = @_;
my (%results, %initial, %links, %output);
my (@uids, @init, @filt);
my ($uid, $final, $file);

# Run ESearch on entire list

$params{'usehistory'} = 'y';
%results = esearch(%params);
$results{'db'} = $params{'db'};

@uids = get_uids(%results);

# Read input index file from elink_by_id

%initial = read_index($params{'infile'});

# Write new index file

unless ($params{'outfile'}) {
   if ($params{'infile'} =~ /(\S+)\.idx$/) { $file = $1; }

   $file .= '_search.idx';
}

open (OUTPUT, ">$file") || die "Can't open $file!\n";    

@links{@uids} = ();

foreach $uid (keys %initial) {

   undef @filt;
   @init = split(/,/, $initial{$uid});

   foreach (@init) {
      push(@filt, $_) if exists $links{$_};
   }
   
   $final = join(',', @filt);
   print OUTPUT "$uid:$final\n";   
}

close OUTPUT;

print "Wrote index file to $file.\n";

return %results;

}

#****************************************************************

sub esummary {

# Performs ESummary. 
# Input: %params:
# $params{'db'} - database
# $params{'id'} - UID list (ignored if query_key exists)
# $params{'query_key'} - query_key
# $params{'WebEnv'} - web environment
# $params{'retstart'} - first DocSum to retrieve
# $params{'retmax'} - number of DocSums to retrieve
# $params{'xml'} - outputs raw ESummary XML unless set to 'n'
# $params{'outfile'} - name of output file for XML (default = docsums)
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: if $params{'xml'} = 'n'
# %results: $results{id}{item} = value where id = UID, item = Item Name
# otherwise XML written to $params{'outfile'}

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);
my @out;
my $id;
my %results;
my ($begin, $end);

sleep($delay);

$url = $base . "esummary.fcgi?db=$params{'db'}&retstart=$params{'retstart'}";
$url .= "&retmax=$params{'retmax'}";

if ($params{'query_key'}) {
   $url .= "&query_key=$params{'query_key'}&WebEnv=$params{'WebEnv'}";   
}
else {
   $url .= "&id=$params{'id'}";   
}

$url .= "&tool=$params{'tool'}&email=$params{'email'}";

print "\n$url\n\n" if ($params{'verbose'});

$begin = time;
$raw = get($url);

if ($params{'xml'} eq 'n') {

@out = split(/^/, $raw);

if ($params{'db'} eq 'homologene') {

$results{'homologene'} = 'y';

 foreach (@out) {

   $id = $1 if (/<Id>(\d+)<\/Id>/);
   if (/<Item Name="(.+)" Type=.*>(.+)<\/Item>/) {
      push(@{$results{$id}{$1}}, $2);
   }   
 }
}

else {

 foreach (@out) {

   $id = $1 if (/<Id>(\d+)<\/Id>/);
   if (/<Item Name="(.+)" Type=.*>(.+)<\/Item>/) {
      $results{$id}{$1} = $2;
   }   

 }
}
}

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

if ($params{'xml'} eq 'n') {
   return %results;
}
else {  
   $params{'outfile'} = 'docsums' unless ($params{'outfile'});
   open (OUTPUT, ">$params{'outfile'}") || die "Can't open $params{'outfile'}!\n"; 
   print OUTPUT $raw;
   close OUTPUT;
   print "Document summaries written to $params{'outfile'}.\n";
}

}

#****************************************************************

sub efetch {

# Performs EFetch. 
# Input: %params:
# $params{'db'} - database
# $params{'id'} - UID list (ignored if query_key exists)
# $params{'query_key'} - query key 
# $params{'WebEnv'} - web environment
# $params{'retmode'} - output data format
# $params{'rettype'} - output data record type
# $params{'retstart'} - first record in set to retrieve
# $params{'retmax'} - number of records to retrieve
# $params{'seq_start'} - retrieve sequence starting at this position
# $params{'seq_stop'} - retrieve sequence until this position
# $params{'strand'} - which DNA strand to retrieve (1=plus, 2=minus)
# $params{'complexity'} - determines what data object to retrieve
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: $raw; raw EFetch output

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);
my ($begin, $end);

sleep($delay);

$url = $base . "efetch.fcgi?db=$params{'db'}";

if ($params{'query_key'}) {
   $url .= "&query_key=$params{'query_key'}&WebEnv=$params{'WebEnv'}";   
}
else {
   $url .= "&id=$params{'id'}";   
}

$url .= "&retmode=$params{'retmode'}&rettype=$params{'rettype'}";
$url .= "&retstart=$params{'retstart'}&retmax=$params{'retmax'}";
$url .= "&seq_start=$params{'seq_start'}&seq_stop=$params{'seq_stop'}";
$url .= "&strand=$params{'strand'}&complexity=$params{'complexity'}";
$url .= "&tool=$params{'tool'}&email=$params{'email'}";

print "\n$url\n\n" if ($params{'verbose'});

$begin = time;
$raw = get($url);

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return($raw);

}

#****************************************************************

sub efetch_batch {

# Uses efetch to download a large data set in 500 record batches
# The data set must be stored on the History server
# The output is sent to a file named $params{'outfile'}
# Input: %params:
# $params{'db'} - link to database
# $params{'query_key'} - query key
# $params{'WebEnv'} - web environment
# $params{'retmode'} - output data format
# $params{'rettype'} - output data record type
# $params{'seq_start'} - retrieve sequence starting at this position
# $params{'seq_stop'} - retrieve sequence until this position
# $params{'strand'} - which DNA strand to retrieve (1=plus, 2=minus)
# $params{'complexity'} - determines what data object to retrieve
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
# $params{'outfile'} - name of output file
#
# Output: nothing returned; raw EFetch output sent to $params{'outfile'}
#   default file name - fetch.out
# Other output: periodic status messages sent to standard output

my %params = @_;
my ($url, $raw);
my ($begin, $end);
my %results;
my ($count, $first, $last);
my ($retstart, $retmax);

$retmax = 500;

#first use ESearch to determine the size of the dataset

$params{'term'} = "%23" . "$params{'query_key'}";
$params{'usehistory'} = 'y';

%results = esearch(%params);

$count = $results{'count'};
$params{'retmax'} = $retmax;

print "Retrieving $count records from $params{'db'}...\n";

$params{'outfile'} = 'fetch.out' unless ($params{'outfile'});

open (OUT, ">$params{'outfile'}") || die "Aborting. Can't open $params{'outfile'}\n";

for ($retstart = 0; $retstart < $count; $retstart += $retmax) {

   sleep($delay);
   $params{'retstart'} = $retstart;
   $begin = time;
   $raw = efetch(%params);
   
   print OUT $raw;

   if ($retstart + $retmax > $count) { $last = $count; }
   else { $last = $retstart + $retmax; }
   $first = $retstart + 1;
   
   print "Received records $first - $last.\n";
   $end = time;
   $delay = $maxdelay - ($end - $begin);
   if ($delay < 0) { $delay = 0; }
}

close OUT;

}

#****************************************************************

sub elink {

# Performs ELink. 
# Input: %params:
# $params{'dbfrom'} - link from database
# $params{'db'} - link to database
# $params{'id'} - array of UID lists (ignored if query_key exists)
# $params{'query_key'} - query key
# $params{'WebEnv'} - web environment)
# $params{'term'} - Entrez term used to limit link results
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: %links: 
# @{$links{'from'}{$set}} = array of input UIDs in set $set
# @{$links{'to'}{$db}{$set}} = array of linked UIDs in $db in set $set
# where $set = integer corresponding to one &id parameter
# value in the ELink URL

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);
my ($line, $getdata, $getid, $link, $id, $set, $name);
my @out;
my @link_ids;
my $ids;
my %results;
my $db;
my ($begin, $end);
my $giveup = 3;

sleep($delay);

$set = 0;

$url = $base . "elink.fcgi?dbfrom=$params{'dbfrom'}&db=$params{'db'}";
$url .= "&term=$params{'term'}";

if ($params{'query_key'}) {
   
   $url .= "&query_key=$params{'query_key'}&WebEnv=$params{'WebEnv'}";
      
}
else {

   foreach $ids (@{$params{'id'}}) {      
      $url .= "&id=$ids";
   }      
}
$url .= "&tool=$params{'tool'}&email=$params{'email'}";

print "\n$url\n\n" if ($params{'verbose'});

$begin = time;
$trial = 0;
$failure = 1;
while (($failure) && ($trial < $giveup)) {
 $raw = get($url);
 if ( ($raw =~ /ERROR/) || ($raw =~ /Error/) || ($raw !~ /<DbFrom>/) ) {
#    print "Links failed. Trying again...\n";
 }
 else { $failure = 0; }   
 $trial++;
}

print "Links failed after $giveup trials. Giving up!\n" if ($failure);

@out = split(/^/,$raw);

$getdata = 0;

foreach $line (@out) {

#check for input UIDs
   $getid = 1 if ($line =~ /<IdList>/);
   if ($getid) {
      
      push (@{$results{'from'}{$set}}, $1) if ($line =~ /<Id>(\d+)<\/Id>/);
  
   }   
   $getid = 0 if ($line =~ /<\/IdList>/);

#check for linked UIDs   
   if ($line =~ /<DbTo>(\S+)<\/DbTo>/) {
      $db = $1;
      $getdata = 1;
      $name = $params{'dbfrom'} . '_' . $db;

   }
   $getdata = 0 if ($line =~ /<\/LinkSetDb>/);
   
   if ($line =~ /<LinkName>(\S+)<\/LinkName>/) {
      $getdata = 0 unless ($name eq $1);
   }   


   if ($getdata) {
          push (@{$results{'to'}{$db}{$set}}, $1) if ($line =~ /<Id>(\d+)<\/Id>/);
   }

   if ($line =~ /<\/LinkSet>/) {
      $getdata = 0;
      $set++;
   }	
		
}

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return(%results);

}

#************************************************************

sub elink_history {

# Uses ELink with &cmd=neighbor_history to post ELink results
# on the History server

# Input: %params:
# $params{'dbfrom'} - link from database
# $params{'db'} - link to database
# $params{'id'} - array of UID lists (ignored if query_key exists)
# $params{'query_key'} - query key
# $params{'WebEnv'} - web environment
# $params{'term'} - Entrez term used to limit link results
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: %links: 
# @{$links{'from'}{$set}} = array of input UIDs in set $set
# $links{'to'}{$set}{$db}{'query_key'} = query_key of linked UIDs in $db in set $set
# $links{'WebEnv'} = Web Environment of linked UID sets
# where $set = integer corresponding to one &id parameter
# value in the ELink URL
# NOTE: If no links are found, query_key will be set to -1

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);
my ($line, $getdata, $getid, $link, $id, $set, $name);
my @out;
my @link_ids;
my $ids;
my %results;
my $db;
my ($begin, $end);

sleep($delay);
$set = 0;

$url = $base . "elink.fcgi?dbfrom=$params{'dbfrom'}&db=$params{'db'}";
$url .= "&cmd=neighbor_history&term=$params{'term'}";

if ($params{'query_key'}) {
   
   $url .= "&query_key=$params{'query_key'}&WebEnv=$params{'WebEnv'}";
      
}
else {

   foreach $ids (@{$params{'id'}}) {      
      $url .= "&id=$ids";
   }      
}
$url .= "&tool=$params{'tool'}&email=$params{'email'}";

print "\n$url\n\n" if ($params{'verbose'});

$begin = time;
$raw = get($url);

@out = split(/^/,$raw);

$getdata = 0;

foreach $line (@out) {

#check for input UIDs
   $getid = 1 if ($line =~ /<IdList>/);
   if ($getid) {
      
      push (@{$results{'from'}{$set}}, $1) if ($line =~ /<Id>(\d+)<\/Id>/);
  
   }   
   $getid = 0 if ($line =~ /<\/IdList>/);

#check for linked UIDs   
   if ($line =~ /<DbTo>(\S+)<\/DbTo>/) {
      $db = $1;
      $getdata = 1;
      $name = $params{'dbfrom'} . '_' . $db;
   }
   $getdata = 0 if ($line =~ /<\/LinkSetDbHistory>/);
   
   if ($line =~ /<LinkName>(\S+)<\/LinkName>/) {
      $getdata = 0 unless ($name eq $1);
   }   

   if ($line =~ /<QueryKey>(\d+)<\/QueryKey>/) {
      $results{'to'}{$set}{$db}{'query_key'} = $1 if ($getdata);
   }
   
   if ($line =~ /<WebEnv>(\S+)<\/WebEnv>/) {
      $results{'WebEnv'} = $1;
   }      

   if ($line =~ /<Info>Empty result<\/Info>/) {
      $results{'to'}{$set}{$db}{'query_key'} = -1 if ($getdata);
   }
         
   if ($line =~ /<\/LinkSet>/) {
      $getdata = 0;
      $set++;
   }	
		
}

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return(%results);

}

#********************************************************************

sub elink_batch {

# Produces links for a single set of records posted on the history server
# from dbfrom to db. The routine segments the set in batches of size $batch
# and then produces a non-redundant set of links for the entire set.

#input hash: {'WebEnv'} = web environment of input set
#	     {'query_key'} = query key of input set
#	     {'id'} = list of UIDs (ignored if query_key exists)
#	     {'dbfrom'} = database of input set, source db
#	     {'db'} = destination db for elink
#	     {'term'} = term parameter for elink

#output: %links{'query_key'} - query key for unique link set
#              {'WebEnv'} - web environment for unique link set

my %params = @_;

my $batch = 100;
my $giveup = 3;
my ($retstart, $first, $last, $max, $trial, $failure, $count);
my (%sparams, %lparams, %hparams, %pparams, %posted, %iparams, $iresults);
my (%sresults, %lresults, %presults, %hresults);
my @links;
my %output;

print "Linking from $params{'dbfrom'} to $params{'db'}...\n";

if ( ($params{'id'}) && (!$params{'query_key'}) ) {

   if ($params{'id'}[0]) {
      $params{'id'} = join(',',@{$params{'id'}});
   }  

   $iparams{'db'} = $params{'dbfrom'};
   $iparams{'id'} = $params{'id'};
   
   %iresults = epost_set(%iparams);
   
   $params{'query_key'} = $iresults{'query_key'};
   $params{'WebEnv'} = $iresults{'WebEnv'};

} 

$batch = 5 if ($params{'dbfrom'} eq $params{'db'});

$sparams{'db'} = $params{'dbfrom'};
$sparams{'term'} = "%23$params{'query_key'}";
$sparams{'retmax'} = $batch;
$sparams{'WebEnv'} = $params{'WebEnv'};
$sparams{'usehistory'} = 'y';


%sresults = esearch(%sparams);
$max = $sresults{'count'};

$lparams{'dbfrom'} = $params{'dbfrom'};
$lparams{'db'} = $params{'db'};
$lparams{'term'} = $params{'term'};

$hparams{'usehistory'} = 'y';
$hparams{'db'} = $params{'db'};
$pparams{'db'} = $params{'db'};

#batch elink from dbfrom to db

for ($retstart=0; $retstart < $max; $retstart += $batch) {

   $sparams{'retstart'} = $retstart;
   
   %sresults = esearch(%sparams);
      
   $lparams{'id'}[0] = join(',', @{$sresults{'uids'}});

   $trial = 0;
   $failure = 1;
   while (($failure) && ($trial < $giveup)) {
     %lresults = elink_history(%lparams);
      if ($lresults{'to'}{0}{$lparams{'db'}}{'query_key'} > 0) {
         $failure = 0;
      }
      elsif ($lresults{'to'}{0}{$lparams{'db'}}{'query_key'} == -1) {
         print "No links found.\n";
	 $trial = $giveup;
      }
      elsif ($trial < $giveup - 1) {
#         print "Links failed. Trying again...\n";
      }	
      else {
         print "Links failed $giveup times. Giving up!\n";
      }	  	 
      $trial++;
   }
  
  unless ($failure) { 
   if ($#links >= 0) {
     
      $pparams{'id'} = join(',', @links);
      $pparams{'WebEnv'} = $lresults{'WebEnv'};
      
      %presults = epost_set(%pparams);
      
      $hparams{'term'} = "%23$presults{'query_key'}";
      $hparams{'term'} .= "+OR+(%23$lresults{'to'}{0}{$lparams{'db'}}{'query_key'}";
      $hparams{'term'} .= "+NOT+%23$presults{'query_key'})";
      $hparams{'WebEnv'} = $presults{'WebEnv'};
   }     
   else {
      $hparams{'term'} = "%23$lresults{'to'}{0}{$lparams{'db'}}{'query_key'}";
      $hparams{'WebEnv'} = $lresults{'WebEnv'};
   }
   
   %hresults = esearch(%hparams);
   $hparams{'retmax'} = $hresults{'count'};
   %hresults = esearch(%hparams);
   @links = @{$hresults{'uids'}} if ($hresults{'uids'}[0]);
  }            
   if (($retstart + $batch) > $max) {
      $last = $max;
   }
   else {
      $last = $retstart + $batch;
   }
   $count = $#links + 1;
   $first = $retstart + 1;
   print "Links complete for records $first - $last. ";
   print "So far, $count unique links.\n";

}

$pparams{'id'} = join(',', @links);

%output = epost_set(%pparams);

return %output;

}

#*********************************************************************

sub elink_by_id {

# Produces links for each member of a set of records posted on the history server
# from dbfrom to db. The routine segments the set in batches of size $batch
# and then produces a set of links for each UID in the set and places these on the
# history using elink_history.

#input hash: {'WebEnv'} = web environment of input set
#	     {'query_key'} = query key of input set
#	     {'id'} = list of UIDs (ignored if query_key exists)
#	     {'dbfrom'} = database of input set, source db
#	     {'db'} = destination db for elink
#	     {'term'} = term parameter for elink
#	     {'get_uids'} = flag for output mode: see below
#	     {'outfile'} = name of index file if get_uids is not 'n'
#			  default = dbfrom_db.idx

#output if get_uids is not 'n' (default): one hash and one file
# %links: 
# $links{'query_key'}, {'WebEnv'} = non-redundant list of UIDs in db linked to all UIDs in dbfrom
# NOTE: If no links are found, query_key will be set to -1
# outfile.idx - index file containing lines of the form
#   input UID in dbfrom:linked UIDs in db (comma-delimited list)

#output: %links: if get_uids = 'n' 
# $links{'id'}{'query_key'} - query key for UIDs in db linked to id in dbfrom
# $links{'id'}{'WebEnv'} - web environment for UIDs in db linked to id in dbfrom



my %params = @_;

my $batch = 20;
my $giveup = 3;
my ($retstart, $max, $trial, $failure, $set, $first, $last, $uid, $file, $num, $expect);
my (@input, @diff, @uids, @temp);
my (%sparams, %lparams, %iparams, %iresults);
my (%sresults, %links, %mark);


if ( ($params{'id'}) && (!$params{'query_key'}) ) {

   if ($params{'id'}[0]) {
      $params{'id'} = join(',',@{$params{'id'}});
   }  

   $iparams{'db'} = $params{'dbfrom'};
   $iparams{'id'} = $params{'id'};
   
   %iresults = epost_set(%iparams);
   
   $params{'query_key'} = $iresults{'query_key'};
   $params{'WebEnv'} = $iresults{'WebEnv'};

} 

$batch = 5 if ($params{'dbfrom'} eq $params{'db'});

$sparams{'db'} = $params{'dbfrom'};
$sparams{'query_key'} = $params{'query_key'};
$sparams{'WebEnv'} = $params{'WebEnv'};

@input = get_uids(%sparams);

$lparams{'dbfrom'} = $params{'dbfrom'};
$lparams{'db'} = $params{'db'};
$lparams{'term'} = $params{'term'};

$max = @input;

print "Linking from $max records in $params{'dbfrom'} to $params{'db'}...\n";

#batch elink from dbfrom to db

for ($retstart=0; $retstart < $max; $retstart += $batch) {

   if (($retstart + $batch) > $max) {
      $last = $max;
      $expect = $last - $retstart;
   }
   else {
      $last = $retstart + $batch;
      $expect = $batch;
   }
   $first = $retstart + 1;
               
   @{$lparams{'id'}} = @input[$retstart..$last-1];
   
 if ($params{'get_uids'} eq 'n') {
# get_uids = n: put results on history
   
   $trial = 0;
   $failure = 1;
   while (($failure) && ($trial < $giveup)) {
     %lresults = elink_history(%lparams);     
     foreach (sort keys %{$lresults{'to'}} ) {
      if ($lresults{'to'}{0}{$lparams{'db'}}{'query_key'} > 0) {
         $failure = 0;
      }
      elsif ($lresults{'to'}{0}{$lparams{'db'}}{'query_key'} == -1) {
         print "No links found.\n";
	 $trial = $giveup;
      }
      elsif ($trial < $giveup - 1) {
#         print "Links failed. Trying again...\n";
      }	
      else {
         print "Links failed after $giveup attempts. Giving up!\n";
      }	  	 
      $trial++;
   }
  } 

# load results into %links

  unless ($failure) {

   print "Links found for records $first - $last.\n";

   foreach $set (sort keys %{$lresults{'from'}} ) {   
      $links{$lresults{'from'}{$set}[0]}{'query_key'} = $lresults{'to'}{$set}{$lparams{'db'}}{'query_key'};
      $links{$lresults{'from'}{$set}[0]}{'WebEnv'} = $lresults{'WebEnv'};
   }
  }
 }

 else {
# get_uids ne n: put UIDs into arrays
   $trial = 0;
   $num = 0;
   %lresults = elink(%lparams);
   
    foreach $key (sort keys %{$lresults{'from'}}) {
   
      $uid = $lresults{'from'}{$key}[0];
      $links{$uid} = join(',', @{$lresults{'to'}{$lparams{'db'}}{$key}} );     
   
    }

    @temp = keys %{$lresults{'from'}};
    $num = @temp;
    if ($num == $expect) {
      print "Links found for records $first - $last.\n";
    }
    else {
      print "WARNING: For records $first - $last, found links for $num out of $expect UIDs.\n";     
    }
     
  }     
}

if ($params{'get_uids'} ne 'n') {
   # write index file and combine UIDs
   if ($params{'outfile'}) { $file = $params{'outfile'} . '.idx'; }
   else { $file = $params{'dbfrom'} . '_' . $params{'db'} . '.idx'; }

   open (OUTPUT, ">$file") || die "Can't open $file!\n";

   foreach $key (keys %links) {

      print OUTPUT "$key:$links{$key}\n";
      @temp = split(/,/, $links{$key});

# make the final UID list non-redundant
      grep($mark{$_}++, @uids);
      @diff = grep(!$mark{$_}, @temp);

      @uids = (@uids, @diff); 

   }

   close OUTPUT; 
      
   print "Wrote link index file to $file.\n";

# post set of UIDs 

   $uidlist = join(',', @uids);

   $pparams{'db'} = $params{'db'};
   $pparams{'id'} = $uidlist;

   %links = epost_set(%pparams); 

}

return %links;

}

#*********************************************************************

sub epost_uids {

# Performs EPost, placing UIDs in the URL. 
# Input: %params:
# $params{'db'} - database
# $params{'id'} - list of UIDs
# $params{'WebEnv'} - Web environment for existing history sets
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
#Output: %results: keys are 'WebEnv' and 'query_key'

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);
my ($begin, $end);

sleep($delay);

$url = $base . "epost.fcgi?db=$params{'db'}&id=$params{'id'}";
$url .= "&WebEnv=$params{'WebEnv'}";
$url .= "&tool=$params{'tool'}&email=$params{'email'}";

print "\n$url\n\n" if ($params{'verbose'});

$begin = time;
$raw = get($url);

$raw =~ /<QueryKey>(\d+)<\/QueryKey>.*<WebEnv>(\S+)<\/WebEnv>/s;
$results{'query_key'} = $1;
$results{'WebEnv'} = $2;

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return(%results);

}

#*********************************************************************

sub epost_file {

# Performs EPost, accepts input from file. 
# Input file must have one UID per line.
# Input: %params:
# $params{'db'} - database
# $params{'id'} - filename containing a list of UIDs
# $params{'WebEnv'} - Web environment for existing history sets
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: %results: keys are 'WebEnv' and 'query_key'

my %params = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my $uids;
my @list;
my ($begin, $end, $count);
my %results;

sleep($delay);

#read input file of UIDs, one per line
open (INPUT, "$params{'id'}") || die "Can't open $params{'id'}\n";

while (<INPUT>) {

   chomp;
   push (@list, $_);

}

$params{'id'} = join (',', @list);

%results = epost_set(%params);

$count = @list;
print "Posted $count records to $params{'db'}.\n";

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return(%results);

}

#***********************************************************

sub epost_set {

# Uses EPost to post a set of UIDs using the POST method
# Useful for large sets of UIDs not from a disk file
# Accepts a comma-delimited list of UIDs in $params{'id'}
# $params{'WebEnv'} - Web environment for existing history sets
# Output: $results{'query_key'}, $results{'WebEnv'}

my (%params) = @_;
my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url_params, $raw, $url);
my ($begin, $end);
my %results;

$url_params = "db=$params{'db'}&id=$params{'id'}";
$url_params .= "&WebEnv=$params{'WebEnv'}";
$url_params .= "&tool=$params{'tool'}&email=$params{'email'}";

$url = $base . "epost.fcgi";

@list = split(/,/, $params{'id'});
$len = @list;

#create user agent
my $ua = new LWP::UserAgent;
$ua->agent("epost_file/1.0 " . $ua->agent);

#create HTTP request object
my $req = new HTTP::Request POST => "$url";
$req->content_type('application/x-www-form-urlencoded');
$req->content("$url_params");

$begin = time;
#post the HTTP request
$raw = $ua->request($req);

$raw->content =~ /<QueryKey>(\d+)<\/QueryKey>.*<WebEnv>(\S+)<\/WebEnv>/s;
$results{'query_key'} = $1;
$results{'WebEnv'} = $2;

$end = time;
$delay = $maxdelay - ($end - $begin);
if ($delay < 0) { $delay = 0; }

return (%results);

}

#***********************************************************

sub print_summary {

# Input: %results output from sub esummary

my %results = @_;
my ($id, $count, $i);
my (@a, @b, @c);

$count = 0;

if ($results{'homologene'} eq 'y') {

 @a = sort keys %results;
 @b = sort keys %{$results{$a[0]}};
 foreach (@b) {
   @c = @{$results{$a[0]}{$_}};
   $count = $#c if ($count < $#c);
 }
 
  foreach $id (sort keys %results) {

   unless ($id eq 'homologene') {
    print "\nID $id:\n";
    for ($i=0; $i <= $count; $i++) {
     foreach (sort keys %{$results{$id}}) {
       print "$_: $results{$id}{$_}[$i]\n" if ($results{$id}{$_}[$i]);
     }
     print "\n";
    }
   } 
 }
}

else {

 foreach $id (sort keys %results) {

   print "\nID $id:\n";
   foreach (sort keys %{$results{$id}}) {
      print "$_: $results{$id}{$_}\n";
   }
 } 
}
}

#***********************************************************

sub print_links {

# Input: %results output from sub elink

my %results = @_;
my ($key, $db);

foreach $key (sort keys %{$results{'from'}}) {
   print "Links from: ";
   foreach (@{$results{'from'}{$key}}) {
      print "$_ ";
   }
   foreach $db (keys %{$results{'to'}}) {
    print "\nto $db:";
    foreach (@{$results{'to'}{$db}{$key}}) {
      print "$_ ";
    } 
   }
   print "\n***\n";   
}

}

#**********************************************************

sub print_link_summaries {

# Input: %results output from sub link_history
# Output: Docsums for linked records arranged by input UID 
# set and linked database

my %results = @_;
my (%params,%docsums);
my ($db, $set);

foreach $set ( sort keys %{$results{'to'}} ) {

   print "Links from set $set\n";
   foreach $db (keys %{$results{'to'}{$set}} ) {

   $params{'db'} = $db;
   $params{'WebEnv'} = $results{'WebEnv'};
   $params{'query_key'} = $results{'to'}{$set}{$db}{'query_key'};
   %docsums = esummary(%params);
   print "$db\n\n";
   print_summary(%docsums);
   print "\n";
   }
}    

}

#**********************************************************

sub get_uids {

# Retrieves all UIDs from an Entrez history set
# Input: %params:
# $params{'WebEnv'} - web environment
# $params{'query_key'} - query_key
# $params{'db'} - database
# Output: array containing UIDs 

my %params = @_;
my %results;

$params{'usehistory'} = 'y';
$params{'term'} = "%23$params{'query_key'}";
%results = esearch(%params);
$params{'retmax'} = $results{'count'};
%results = esearch(%params);

return @{$results{'uids'}};

}

#*********************************************************

sub read_index {

# reads index file (.idx) produced by elink_by_id or search_links
# Output: hash %index: $index{id} = comma-delimited list of linked UIDs

my $file = $_[0];
my %index;
my ($key, $list);

open (INPUT, "$file") || die "Can't open $file!\n";

while (<INPUT>) {

   chomp;
   ($key, $list) = split(/:/, $_);
   $index{$key} = $list;

}

close INPUT;

return %index;

}

1; #End of module
