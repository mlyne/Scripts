#!/usr/bin/perl
use strict;
use warnings;
use DateTime;
use LWP::Simple;
use utf8;
use Text::Unidecode;

binmode STDOUT, ':encoding(UTF-8)';

# Take input from the command line
my $term_file = $ARGV[0];

# Open Drug
open(TFILE, "< $term_file") || die "cannot open $term_file: $!\n";

# Get local time and write to file
my $stamp = DateTime->now( time_zone => 'Europe/London' );

# Loops through Drug file
READ_TERM_LOOP:while (<TFILE>)
{
  chomp; # remove newlines
  my $searchQ = $_;
  
# If it contains a regular expression - get rid of it
  my ($shortTerm) = ($searchQ =~ m/^\(*(.+?)\[.+$/) ? $1 : $searchQ;
  $shortTerm =~ s/ /_/g;
  $shortTerm =~ s/\//_/g;
  $shortTerm =~ s/\"//g;
#  print $shortTerm, "\n";


my $db = 'pubmed';
my $query = "$searchQ+AND+1995:2013[dp]+NOT+review[pt]";

## Search Term Examples
#my $query = 'asthma[mesh]+AND+leukotrienes[mesh]+AND+2009[pdat]';
#my $query = '(diabetes[mh] AND (cambridge[ad] AND 2011[pdat])';
#my $query = '(("Behcet Syndrome"[mh]) AND (human[mh])) AND Italy[ad])';

#assemble the esearch URL
my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
my $url = $base . "esearch.fcgi?db=$db&term=$query&usehistory=y" .
        "&tool=eSearchTool_time" .
        "&email=mlyne\.careers\@gmail.com";

# Check the time ###
Time_Check();

#post the esearch URL
my $output = get($url);
#select(undef, undef, undef, 0.5); # PubMed requires that we have no more than 3 requests / second so delay half second

#print "$output";

#parse count
my $count = $1 if ($output =~ /<Count>(\S+)<\/Count>/);
#print "Count: ", $count, "\n";

#parse WebEnv and QueryKey
my $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
my $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);

### include this code for ESearch-ESummary
#assemble the esummary URL
$url = $base . "esummary.fcgi?db=$db&query_key=$key&WebEnv=$web";

#post the esummary URL
#my $docsums = get($url);
#print "$docsums";
#my $pmid = $1 if ($docsums =~ /<Id>(\d+)<\/Id/);
#print "PMID: ", $pmid, "\n";


### include this code for ESearch-EFetch
#assemble the efetch URL
$url = $base . "efetch.fcgi?db=$db&query_key=$key&WebEnv=$web";
$url .= "&rettype=abstract&retmode=xml";

# open XML OUT_FILE for writing
my $outFile = "clin_$shortTerm";
#print $outFile, "\n";
open(OUT_FILE, "> $outFile.xml") || die "cannot open $outFile: $!\n";

#post the efetch URL
my $data = get($url);
#print "$data";
my $decode = unidecode($data);
print OUT_FILE "$decode";

close (OUT_FILE);

}# End TERM_LOOP

close (TFILE);

sub Time_Check {
        
        my $early = "2100";
        my $late = "0500";
        #my $late = "0220"; 

        my$locTime = localtime();
        print "Local Time: ", $locTime, "\n";
        
        my $t = DateTime->now( time_zone => 'America/New_York' ); # Change zone to Eastern Time
        print $t->hms, " : Eastern Time\n";

        my @ltime = split(/:/, $t->hms);
        my $hour = $ltime[0];
        #$hour +=4; # Fiddle factor to get over the midnight bridge
        my $min = $ltime[1];
        my $time = "$hour$min";
        #my $time = "$ltime[0]$ltime[1]";
        #print "time ", $time, "\n";
        #print "hour ", $hour, "\n";

        my $dayNum = $t->wday; # 1-7 (Monday is 1) - 
                print "day ", $dayNum, " (Monday is 1)\n";

        #unless (($dayNum < 2) || ($dayNum > 5)) {
        unless ( $dayNum > 5 ) {

                while ($time <= $early && $time >= $late) {
                        print $t->hms, " Eastern Time: time to sleep ($time)\n";
                        sleep 10;
                        
                        $t = DateTime->now( time_zone => 'America/New_York' );
                        @ltime = split(/:/, $t->hms);
                        $hour = $ltime[0];
                        #$hour +=4; # Fiddle factor to get over the midnight bridge
                        $min = $ltime[1];
                        $time = "$hour$min";
                        
                }
        #$dayNum = $t->wday; # 1-7 (Monday is 1)
        }
                
}
