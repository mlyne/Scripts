#!/usr/bin/perl -w

# pragmas
use strict;

$/ = "//";

my (@result, @results);

while (<>) 
    {    
    chomp;
    
	my @lines = split(/\n/, $_);
	my $locus;
	@result = ();
	foreach my $line (@lines)
	{
		chomp;
	  	
	  	if ($line =~ /^LOCUS\s+(.+?)\s/)
		{
	  		my $gene_id = $1;
#	  		print "$gene_id\n";
	  		push (@result, $gene_id);
	  	}
	  	
	  	if ($line =~ /^VERSION\s+(.M_\d+\.\d+)\s+/)
	  	{
	  		$locus = $1;
	 		push (@result, $locus);
#	    	print "$locus\n";
		}
				
		if ($line =~ /\/db_xref=\"MIM:(\d+)\"/)
		{
	  		my $omim = $1;
	  		print "$omim\n";
	  		push (@result, $omim);
	  	}
	  		  	
	  	if ($line =~ /\/protein_id=\"([XN]P_\d+\.\d+)\"/)
		{
	  		my $prot_id = $1;
#	  		print "$prot_id\n";
	  		unshift (@result, $prot_id);
	  	}
	  	
	}
	print join("\t", @result), "\n";
	print scalar(@result), "\n";
	push(@results, [@result]);			 	
}


for my $arRef (@results)
{
#	print "$arRef->[0]\t";
#	print "$arRef->[2]\t";
#	print "$arRef->[1]\t";
#	if (defined ($arRef->[3]))
#	{
#		print "$arRef->[3]\n";
#	} else { print "NONE\n"; }
	
}