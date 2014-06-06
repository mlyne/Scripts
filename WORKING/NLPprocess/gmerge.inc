#!/usr/local/bin/perl5

# merge-sorts two files sorted on first column of scientific notation,
#	in increasing order
# first file has precedence in case of equal keys

#check for correct usage
if ($#ARGV < 0) {
        print "usage:  gmerge <file1> [<file2>]\n";
        exit; 
};

open(F1, @ARGV[0]) || die "Couldn't open @ARGV[0]: $!\n";

shift(@ARGV);

$line1 = <F1>;
($key1, @rest1) = split(/\s+/, $line1);

while (<>) {
    ($key2, @rest2) = split;
    $line2 = $_;
    if ($key2 < $key1) {
	print $line2;
	if (eof()) {
	    print $line1;
	    while (<F1>) { print; };
	    exit;
	};
    } else {
	print $line1;
	if (eof(F1)) {
	    print $line2;
	    while (<>) { print; };
	    exit;
	} else {
	    while (<F1>) {
		($key1, @rest1) = split;
		$line1 = $_;
		if ($key2 < $key1) {
		    print $line2;
		    last;
		} else {
		    print $line1;
		};
	    };
	};
    };
};
