#!/bin/bash

# sh cloneID_BlastParse.sh

while  getopts f c
do
       case "$c" in
       f) FLAG="$c";;
       esac
done
shift `expr $OPTIND - 1`


if [ $# -ne 1 ]
# check proper # of command line args.
then
    echo "Usage: `basename $0` [-f full notation] BLASTfile.gz"
    exit 1
fi

filename=$1
scrpdir="/home2/mlyne/SCRIPTS"

if [ "$FLAG" ]
then
    gzip -dc $filename | /biosoft/arch/bin/MSPcrunch -d -| sort -nr | $scrpdir/BLAST/msp2hits2.pl -r 5 | sort +3 | $scrpdir/BLAST/nr_list.pl -d | awk '{if ( ($1 > 200) && ($6 !~ /expand/) ) print }' | $scrpdir/BLAST/rmNegSecHits.pl
else
    gzip -dc $filename | /biosoft/arch/bin/MSPcrunch -d -| sort -nr | $scrpdir/BLAST/msp2hits2.pl -r 5 | sort +3 | $scrpdir/BLAST/nr_list.pl -d | awk '{if ( ($1 > 200) && ($6 !~ /expand/) ) print $4, $6, $1, $2}' | $scrpdir/PFAM_PARSE/all_pfam_domains.pl | $scrpdir/BLAST/not_neg_drug.pl
fi

exit 0

