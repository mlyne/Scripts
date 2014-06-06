Example of using bash to loop through a file and execute a script using the file vaues

$ for i in `cat a` ; do /home/MIKE/SCRIPTS/HANDY/fastagrep.pl -D -P -p $i highC
onfInfo.txt; done > b