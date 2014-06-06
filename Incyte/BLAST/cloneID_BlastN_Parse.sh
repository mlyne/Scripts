#!/bin/bash

# sh cloneID_BlastParse.sh

if [ $# -ne 1 ]
# check proper # of command line args.
then
    echo "Usage: `basename $0` BLASTfile.gz"
    exit 1
fi

filename=$1

gzip -dc $filename | /biosoft/arch/bin/MSPcrunch -d -I 98 -| perl -pe 's/(T|R|H|F|CB|CA)\d//' | sort -nr |awk '{if ($1>1000) print}' | /home2/mlyne/SCRIPTS/BLAST/msp2hits2.pl -r 5 | /home2/mlyne/SCRIPTS/BLAST/nr_list.pl | sort +3 |awk '{if ($6 !~ /negative-secreted/) print $4, $6, $1, $2}' | /home2/mlyne/SCRIPTS/PFAM_PARSE/all_pfam_domains.pl 

exit 0
