#!/usr/local/bin/perl5

########################################################################
# Author:  I. Dan Melamed
# Computes:	merges multiple string-sorted files, ignoring first column
# Streams:	all the files
#######################################################################

$| = 1;

#check for correct usage
if ($#ARGV < 0) {
    print "usage: multimerge2.inc <file1> [<file2> ...] \n";
    exit; 
};

push(@INC, "$ENV{TRALECDIR}/bin");
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
	$line[$i] =~ /^([^ ]+) *(.*)$/;
	$key[$i] = $2;
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
	$line[$winner] =~ /^([^ ]+) *(.*)$/;
	$key[$winner] = $2;
    };
};



