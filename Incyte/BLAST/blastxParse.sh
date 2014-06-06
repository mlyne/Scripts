#!/bin/bash

# sh blastnParse.sh
while  getopts t c
do
       case "$c" in
       t) FLAG="$c";;
       esac
done
shift `expr $OPTIND - 1`

USAGE="Usage: `basename $0` BLASTfile.gz"

if [ $# -ne 1 ]
# check proper # of command line args.
then
    echo $USAGE
    exit 1
fi

filename="$1"
scrpdir="/home2/mlyne/SCRIPTS"

if [ "$FLAG" ]
then
    gzip -dc "$filename" | /biosoft/arch/bin/MSPcrunch -d -| sort -nr | $scrpdir/BLAST/msp2hits2.pl -t | sort +3 | awk '{if  ($1 >= 200) print $4, $6, $1, $2}' | $scrpdir/PFAM_PARSE/all_pfam_domains.pl 
else
    gzip -dc "$filename" | /biosoft/arch/bin/MSPcrunch -d -| sort -nr | $scrpdir/BLAST/msp2hits2.pl -r 5 | $scrpdir/BLAST/nr_list.pl | sort +3 | awk '{if  ($1 >= 200) print $4, $6, $1, $2}' | $scrpdir/PFAM_PARSE/all_pfam_domains.pl 
fi

exit 0
