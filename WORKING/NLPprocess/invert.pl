#!/usr/local/bin/perl5

########################################################################
# creates inversions in a token stream, using inversion descriptions
#    from a file
#######################################################################

#check for correct usage
if ($#ARGV < 0) {
    print "usage:  invert <inversion description file> <input file>\n";
    exit; 
};

open(F, $ARGV[0]) || die "Couldn't open $ARGV[0]: $!\n";
shift(@ARGV);
open(I, $ARGV[0]) || die "Couldn't open $ARGV[0]: $!\n";
shift(@ARGV);
$point = 1;
while (<F>) {
    ($start, $size, $move) = split;

    # find line where inversion starts
    while ($point < $start) {
	$stream = <I>;
	if (eof) {die "Not enough input!\n";};
	if ($stream !~ /<EOL>/) {
	    $point++;
	};
	print $stream;
    };

    while ($point < $start + $move) {
	$stream = <I>;
	if (eof) {die "Not enough input!\n";};
	if ($stream !~ /<EOL>/) {
	    $point++;
	};
	push(@save, $stream);
    };

    while ($point < $start + $size) {
	$stream = <I>;
	if (eof) {die "Not enough input!\n";};
	if ($stream !~ /<EOL>/) {
	    $point++;
	};
	print $stream;
    };

    foreach $token (@save) {
	print $token;
    };
    undef(@save);

};
close(F);

# print the remainder of input without inversions
while (<I>) {
    print;
};

