#!/usr/local/bin/perl5

########################################################################
# Author:  I. Dan Melamed
# Computes:	merges multiple string-sorted files
# Streams:	all the files
# N.B.:		
#######################################################################

$| = 1;

#check for correct usage
if ($#ARGV < 0) {
    print "usage: multimerge.inc <file1> [<file2> ...] \n";
    exit; 
};

push(@INC, "/mnt/unagi/nldb/melamed/bin");
require "idmlib.pl";

$counter = 1;
while (@ARGV) {
    $handlename = "H".$counter;
    open($handlename, $ARGV[0]) || die "Couldn't open $ARGV[0]: $!\n";
    push(@fileptr, \*$handlename);
    shift;
    $counter++;
};

for($i = 0; $i < @fileptr; $i++) {
    if (eof($fileptr[$i])) {
	splice(@fileptr, $i, 1);
	$i--;
    } else {
	$handle = $fileptr[$i];
	$line[$i] = <$handle>;
	$key[$i] = $line[$i];
    };
};

while (@fileptr) {
    $winner = &minar_string(\@key, [0 .. $#key]);
    print $line[$winner];

    if (eof($fileptr[$winner])) {
	splice(@fileptr, $winner, 1);
	splice(@key, $winner, 1);
	splice(@line, $winner, 1);
    } else {
	$handle = $fileptr[$winner];
	$line[$winner] = <$handle>;
	$key[$winner] = $line[$winner];
    };
};



