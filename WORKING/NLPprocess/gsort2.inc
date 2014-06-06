#!/usr/local/bin/perl5

# sorts on first two numeric columns
# works for scientific notation and decimals

while (<>) {
    ($val1, $val2, $rest) = split(' ', $_, 3);
    $val1[$.] = $val1;
    $val2[$.] = $val2;
    $rest[$.] = $rest;
};

foreach $ln (sort {$val1[$a] <=> $val1[$b] || $val2[$a] <=> $val2[$b]} 
	     (0 .. $#val1)) {
    print "$val1[$ln] $val2[$ln] $rest[$ln]";
};
