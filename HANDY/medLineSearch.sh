
#!/bin/bash

# sh medLineSearch.sh

USAGE="Usage: `basename $0` drugFile \"query\"
***Query examples:
1) AND+inflammation
2) AND+(tramadol+OR+venlafaxine)***"

if [ $# -ne 2 ]
# check proper # of command line args.
then
    echo $USAGE
    exit 1
fi

filename="$1"
query="$2"


for i in `cat $filename` ; do /home/MIKE/SCRIPTS/WORKING/LWPscripts/medTest.pl $i $query| grep PMID |  perl -pe 's/.+PMID: (\d+) .+$/$1/' >> RES/uid.$i ; done

for i in `cat $filename` ; do echo "> $i" >> RES/$filename.txt; for s in `cat RES/uid.$i`; do /home/MIKE/SCRIPTS/WORKING/LWPscripts/uidTest.pl $s >> RES/$filename.txt; done; done

exit 0