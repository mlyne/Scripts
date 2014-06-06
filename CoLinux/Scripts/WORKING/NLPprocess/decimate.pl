#!/usr/local/bin/perl5

########################################################################
# creates holes in a token stream, using hole descriptions from a file
#######################################################################

#check for correct usage
if ($#ARGV < 0) {
    print "usage:  decimate <hole description file> <input file>\n";
    exit; 
};

open(H, $ARGV[0]) || die "Couldn't open $ARGV[0]: $!\n";
shift;
open(I, $ARGV[0]) || die "Couldn't open $ARGV[0]: $!\n";
shift;
$point = 1;
while (<H>) {
    ($start, $size) = split;
    
    # find line where hole starts
    while ($point < $start) {
	$stream = <I>;
	if (eof) {die "Not enough input!\n";};
	if ($stream !~ /<EOL>/) {
	    $point++;
	};
	print $stream;
    };

    while ($point < $start + $size) {
	$stream = <I>;
	if (eof) {die "Not enough input!\n";};
	if ($stream !~ /<EOL>/) {
	    $point++;
	};
    };
};
close(H);

# print the remainder of input without holes
while (<I>) {
    print;
};

