ever wanted a range operator (i.e. like perl's 1..100) in bash? here are 2 possible solutions:
for i in `seq 1 100`; do ..
for((i=1;i<101;i++))range of lines from a file *** sed -n '<from>,<to>p;<to>q' file
