perl -nle 'print scalar lc a' inflamDrug.txt > a
change words to lower case---

EDIT IN PLACE
# 1. in-place edit of *.c files changing all foo to bar
perl -p -i.bak -e 's/\bfoo\b/bar/g' *.c

# 2. delete first 10 lines
perl -i.old -ne 'print unless 1 .. 10' foo.txt

# 3. change all the isolated oldvar occurrences to newvar
perl -i.old -pe 's{\boldvar\b}{newvar}g' *.[chy]

# 4. increment all numbers found in these files
perl -i.tiny -pe 's/(\d+)/ 1 + $1 /ge' file1 file2 ....

# 5. delete all but lines between START and END
perl -i.old -ne 'print unless /^START$/ .. /^END$/' foo.txt

REVERSING
# 1. command-line that reverses the whole input by lines
#    (printing each line in reverse order)
perl -e 'print reverse <>' file1 file2 file3 ....

# 2. command-line that shows each line with its characters backwards
perl -nle 'print scalar reverse $_' file1 file2 file3 ....

# 3. find palindromes in the /usr/dict/words dictionary file
perl -lne '$_ = lc $_; print if $_ eq reverse' /usr/dict/words

# 4. command-line that reverses all the bytes in a file
perl -0777e 'print scalar reverse <>' f1 f2 f3 ...

# 5. command-line that reverses each paragraph in the file but prints
#    them in order
perl -00 -e 'print reverse <>' file1 file2 file3 ....

HMMM....
# 1. write command to mv dirs XYZ_asd to Asd
# (you may have to preface each '!' with a '\' depending on your shell)
ls | perl -pe 's!([^_]+)_(.)(.*)!mv $1_$2$3 \u$2\E$3!gio'

# 2. Write a shell script to move input from xyz to Xyz
ls | perl -ne 'chop; printf "mv $_ %s\n", ucfirst $_;'
