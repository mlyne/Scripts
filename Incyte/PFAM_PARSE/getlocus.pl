#!/usr/localbin/perl -w

while (<>)
{
    chomp;
    $seq=$_;
    $seq=~s/\w+\:(.+)\.\d/$1/;
    @aq=`aQ -vd ~acedata/databases/cgc/ "find sequence; query *$seq; follow source; follow gene_summary_cdna; list -a"`;
    @locus = grep /Locus/, @aq;
    chomp @locus;
    $locus=shift @locus;
    if ($locus)
    {
	$locus =~ s/Locus : //;
	$locus =~ s/\"//g;
	print "$locus\t$_\n";
    }else{
	print "failed to find locus for $_\n";
    }

}
