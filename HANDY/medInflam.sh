
#!/bin/bash

# sh medInflam.sh

USAGE="Usage: `basename $0` medInflam.sh"

if [ $# -ne 1 ]
# check proper # of command line args.
then
    echo $USAGE
    exit 1
fi

filename="$1"



for i in `cat $filename` ; do /home/MIKE/SCRIPTS/WORKING/medTest.pl $i | grep PMID |  perl -pe 's/.+PMID: (\d+) .+$/$1/' >> RES/uid.$i ; done

for i in `cat $filename` ; do echo "> $i" >> RES/data.txt; for s in `cat RES/uid.$i`; do /home/MIKE/SCRIPTS/WORKING/uidTest.pl $s >> RES/data.txt; done; done

exit 0