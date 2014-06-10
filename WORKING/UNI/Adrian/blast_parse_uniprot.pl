#!/usr/bin/perl
use warnings;

# start timer
my $start = time();

$blast_results_file = $ARGV[0];    #FASTA

$uniprot_file = $ARGV[1];

open IN, "$blast_results_file" or die "can't open file";
while (<IN>) {
    chomp $_;
    @split = split( /\t/, $_ );
    $split[0] =~ /^(Locus_\d+)_Tran/;
    $evalue = $split[10];
    $locus  = $1;

    #print "$split[1]\n";
    $split[1] =~ /\|\S+\|[^_]+_([^:]+)/;
    $symbol = $1;
    $split[1] =~ /\|(\S+)\|/;
    $accession = $1;

    #print "$locus\t$symbol\t$evalue\t$accession\n";

    if ( $evalue{$locus} ) {

        if ( $evalue{$locus} >= $evalue ) {
            $evalue{$locus}    = $evalue;
            $symbol{$locus}    = $symbol;
            $accession{$locus} = $accession;
        }
    }
    else {

        $evalue{$locus}    = $evalue;
        $symbol{$locus}    = $symbol;
        $accession{$locus} = $accession;

    }

}

close IN;

foreach $locus ( keys %accession ) {
    $accession_hash{ $accession{$locus} } = 1;
}

open IN, "$uniprot_file" or die "can't open file";
$hit = 0;
while (<IN>) {
    if ( $_ =~ /^AC\s+(.+);/ ) {

        @accessions = split( /; /, $1 );

        $hit = 0;
        foreach $syn (@accessions) {
            if ( $accession_hash{$syn} ) {
                $current_accession = $syn;
                $hit               = 1;
            }

        }

    }
    if ( $hit == 1 ) {
        if ( $_ =~ /^OS\s+(.+)/ ) { $os{$current_accession} = $1; }
        if ( $_ =~ /^OC\s+(.+)/ ) { $oc{$current_accession} .= "$1 "; }
        if ( $_ =~ /^DR\s+Pfam; (.+)/ ) {
           $current_pfam{$current_accession} .= "$1 ";
        }
        if ( $_ =~ /^DR\s+GO; (.+)/ ) {
            $current_go{$current_accession} .= "$1 ";
        }
        if ( $_ =~ /^DE\s+(.+)/ ) {
            $current_fullname{$current_accession} = $1;
        }
        if ( $_ =~ /^GN\s+(.+)/ ) { $current_name{$current_accession} = $1; }
    }
}

foreach $locus ( keys %symbol ) {

    print
"$locus\t$evalue{$locus}\t$accession{$locus}\t$current_name{$accession{$locus}}\t$current_fullname{$accession{$locus}}\t$current_pfam{$accession{$locus}}\t$current_go{$accession{$locus}}\t$os{$accession{$locus}}\t$oc{$accession{$locus}}\n";

}

# end timer
my $end = time();

# report
#print "\nTime taken was ", ( $end - $start ), " seconds\n";

