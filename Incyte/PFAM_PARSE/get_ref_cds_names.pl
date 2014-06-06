#!/usr/localbin/perl -w

    @aq=`aQ -vd ~acedata/databases/cgc/ "find sequence; follow gene_cds; follow reference_cds; follow gene_summary_cdna; list -a"`;
