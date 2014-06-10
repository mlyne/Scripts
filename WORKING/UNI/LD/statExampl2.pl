#! /usr/local/bin/perl -w 

# Copyright @ 2004 - 2014 The Institute for Genomic Research (TIGR).
# All rights reserved.
# 
# This software is provided "AS IS".  TIGR makes no warranties, express or
# implied, including no representation or warranty with respect to the
# performance of the software and derivatives or their safety,
# effectiveness, or commercial viability.  TIGR does not warrant the
# merchantability or fitness of the software and derivatives for any
# particular purpose, or that they may be exploited without infringing the
# copyrights, patent rights or property rights of others.
# 

use strict;
use Statistics::Descriptive;

my @data = get_file_data($ARGV[0]);
my $query1 = "GENOME QUERY 1";
my $query2 = "GENOME QUERY 2";
my @r1;
my @r2;
my $i =0;
foreach my $line (@data) {

    my @tp= split ("\t", $line);

    push (@r1, $tp[4]);
    push (@r2, $tp[7]);
    $i++;

}

########### STATISTICAL ANALYSIS ########################################

 my $stat1 = Statistics::Descriptive::Full->new();
 my $stat2 = Statistics::Descriptive::Full->new();
 $stat1->add_data(@r1); 
 $stat2->add_data(@r2);
 my $median1 = $stat1->median();
 my $median2 = $stat2->median();
 my $variance1 = $stat1->variance();
 my $variance2 = $stat2->variance();
 my $std1 = $stat1->standard_deviation();
 my $std2 = $stat2->standard_deviation();
 my $mean1 = $stat1->mean();
 my $mean2 = $stat2->mean();
 my $count1 = $stat1->count();
 my $count2 = $stat2->count();

##### COMPUTE THE MEDIAN ABSOLLUTE DEVIATION (Median of abs|Xi -Med(Xi)| ######

my @mad1;
my @mad2;
my $absmed1;
my $absmed2;

foreach my $med1 (@r1) {
    chomp $med1;
    $absmed1 = abs($med1 - $median1);
    push (@mad1, $absmed1);
}

foreach my $med2 (@r2) {
    chomp $med2;
    $absmed2 = abs($med2 - $median2);
    push (@mad2, $absmed2);
}

my $statm1 = Statistics::Descriptive::Full->new();
my $statm2 = Statistics::Descriptive::Full->new();
$statm1->add_data(@mad1); 
$statm2->add_data(@mad2);
my $medabs1 = $statm1->median() * 1.4826;
my $medabs2 = $statm2->median() * 1.4826;

##### FORMATTING DATA FOR OUTPUT ##############

$medabs1 = sprintf ("%.4f", $medabs1);
$medabs2 = sprintf ("%.4f", $medabs2);
$median1 = sprintf ("%.4f", $median1);
$median2 = sprintf ("%.4f", $median2);
$variance1 = sprintf ("%.4f",$variance1);
$variance2 = sprintf ("%.4f",$variance2);
$std1 = sprintf ("%.4f",$std1);
$std2 = sprintf ("%.4f",$std2);
$mean1 = sprintf ("%.4f",$mean1);
$mean2 = sprintf ("%.4f",$mean2);
$count1 = sprintf ("%.f",$count1);
$count2 = sprintf ("%.f",$count2);

my $a = "PROTEIN ANALYZED";
my $t = "MEDIAN";
my $g = "MEAN";
my $c = "STD DEVIATION";
my $at = "VARIANCE";
my $cg = "MED ABS DEVIATION";
my $spce = "-";
format STDOUT_TOP =
             STATISTICAL ANALYSIS OF THE OVERALL BSR DATA
        @||||||||||||||||  @||||||||||||||||| @|||||||||||||||||
        $spce,             $query1,           $query2,      
        --------------------------------------------------------
.


format STDOUT =
        @||||||||||||||||  @||||||||||||||||| @|||||||||||||||||
        $a,                $count1,           $count2,     
        --------------------------------------------------------
        @||||||||||||||||  @||||||||||||||||| @||||||||||||||||| 
        $t,                $median1,          $median2,  
        --------------------------------------------------------
        @||||||||||||||||  @||||||||||||||||| @|||||||||||||||||
        $g,                $mean1,            $mean2,    
        --------------------------------------------------------
        @||||||||||||||||  @||||||||||||||||| @|||||||||||||||||
        $c,                $std1,             $std2,    
        --------------------------------------------------------
        @||||||||||||||||  @||||||||||||||||| @|||||||||||||||||
        $at,               $variance1,        $variance2,    
        --------------------------------------------------------
.       @||||||||||||||||  @||||||||||||||||| @||||||||||||||||| 
        $cg,               $medabs1,          $medabs2,     
        --------------------------------------------------------
.

    write;


exit;


# A Subroutine to Read Files into array
sub get_file_data {

    my($filename) = @_;

    use strict;
    use warnings;

    # Initialize variables
    my @filedata = (  );

    unless( open(GET_FILE_DATA, $filename) ) {
        print STDERR "Cannot open file \"$filename\"\n\n";
        exit;
    }

    @filedata = <GET_FILE_DATA>;

    close GET_FILE_DATA;

    return @filedata;
}
