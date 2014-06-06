#!/usr/bin/perl -w

# Takes the parsed Derwent Druge file index
# and rearranges by drug\tdrug class1, dc2 etc

use strict;
 
my $file = $ARGV[0];

open(FILEO, "< $file") || die "cannot open $file: $!\n";

my @array;
{
 local $/ = '> ';
 @array = <FILEO>;
}
shift(@array);
my %drugHash = ();

foreach my $entry (@array)
{
	my @lines = split(/\n/, $entry);
	my $drugClass = shift(@lines);
	$drugClass =~ tr/[A-Z]/[a-z]/;
	$drugClass =~ s/^([a-z])/uc($1)/e;
	#print $drugClass, " Class\n";
	
	foreach my $drug (@lines) {
		next if ($drug =~ />/);
		$drug =~ tr/[A-Z]/[a-z]/;
		$drug =~ s/^([a-z])/uc($1)/e;
		push( @{$drugHash{$drug}}, $drugClass );
		
		#print $drug, " Drug\n";
	}
		
	
#	print "Before****\n", $entry, "\nAfter***********\n";

}

foreach my $drugKey (sort keys %drugHash) {
  print "$drugKey\t", join(", ", @{$drugHash{$drugKey}} ), "\n";
}