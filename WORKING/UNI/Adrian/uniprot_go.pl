#!/usr/bin/perl
use warnings;

# start timer
my $start = time();

$uniprot_accessions = $ARGV[0];    #FASTA
$uniprot_file = $ARGV[1];

open IN, "$uniprot_accessions" or die "can't open file";
while (<IN>) {
    chomp $_;
    $accession_hash{$_} = 1;
}

close IN;


open IN, "$uniprot_file" or die "can't open file";
$hit = 0;
while (<IN>) {
    if ( $_ =~ /^AC\s+(.+);/ ) {

        @accessions = split( /; /, $1 );

        $hit = 0;
        foreach $syn (@accessions) {
            if ( $accession_hash{$syn} ) {
                #$current_accession = $syn;
                $hit               = 1;
            }

        }

    }
    if ( $hit == 1 ) {
        
        if ( $_ =~ /^DR\s+GO;\s([^;]+);([^;]+)/g ) {
           $pfam_counter{"$1\t$2"} += 1;
		#print "$1\t$2\n";
        }
        
    }
}

foreach $pfam  (sort { $pfam_counter {$b} <=> $pfam_counter {$a}} keys %pfam_counter ){


    print "$pfam_counter{$pfam}\t$pfam\n";

}

# end timer
my $end = time();

# report
#print "\nTime taken was ", ( $end - $start ), " seconds\n";

