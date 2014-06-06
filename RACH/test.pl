print "Input a number \n";

chomp($in = <STDIN>);

print "$in\n";

$odd = $in % 2;

if ($odd) {
print "$in is an odd number!\n";
} else {
print "$in is an even number!\n";
}