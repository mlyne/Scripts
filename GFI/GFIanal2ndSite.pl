#!/usr/bin/perl -w
#
#

my ($score, $desc, $secSite);
my %hash;

while (<>) {
	chomp;
#	(undef, $score, undef, $desc, undef, $secSite) = split("\t", $_);
	($score, $desc, $secSite) = split("\t", $_);
	
	unless (($score eq "NONE") || ($desc eq "NONE")) {
		push( @{$hash{$secSite}}, [$score, $desc]);
	}
}

for my $site (sort keys %hash) {
	for my $value (@{ $hash{$site} }) {
		print "$site\t", join("\t", @$value), "\n";
	}
}