#!/bin/bash

# sh transfer.sh File2transfer

USAGE="Usage: `basename $0` File2transfer"

if [ $# -ne 1 ]
# check proper # of command line args.
then
    echo $USAGE
    exit 1
fi

filename="$1"

scp -C mlyne@guardian.incyte.com:/data/isb2k/blastdb/FL_MASTER/"$filename" .

exit 0
