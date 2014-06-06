Perl one-liners

Replace sep
perl -ne 'BEGIN {$sep=","}' -e 's/\Q$sep\E/\t/g; print $_; END {warn "Changed $sep to tab on $. lines\n"}' file.csv > file.tab
perl -ne 'BEGIN {$sep=","}' -e 's/\t/$sep/g; print $_; END {warn "Changed tab to $sep on $. lines\n"}' file.tab > file.csv

No Spaces
perl -ne 's/ //g; print $_; END {warn "Removed all spaces from $. lines\n"}' file.spaces > file.nospace

Lowercase
perl -ne 'print lc($_); END {warn "Changed $. lines to upper case\n"}' file.mixed > file.uc

Columns
Select
perl -ne 'BEGIN {@cols=(1, -1, 2)}' -e 's/\r?\n//; @F=split /\t/, $_; print join("\t", @F[@cols]), "\n"' all_cols > some_cols

Delete
perl -ne 'BEGIN {@del_col = (0, 4..7, -1)}' -e 's/\r?\n//; @F=split /\t/, $_; foreach $col (sort {$b <=> $a} @del_col) {splice @F, $col, 1}; print join("\t", @F),"\n"; END {warn "Deleted cols @del_col for $. lines\n"}' all_cols > some_cols

Grep
perl -ne 'BEGIN {$string=q{>CG};}' -e 'BEGIN {$count=0}; if (/\Q$string\E/) {print $_; $count++} END {warn qq{Chose $count lines with string "$string" out of $. total lines.\n}}' a.fsa > descs

Blank Lines
perl -ne 'BEGIN {$count=0}; if (/^\s*$/) {$count++} else {print $_} END {warn "Removed $count blank/whitespace lines out of $. total lines.\n"}' infile > noblanks

Filter by value
perl -ne 'BEGIN {$col=-1; $limit=80;}' -e 'BEGIN {$count=0} s/\r?\n//; @F=split /\t/, $_; if ($F[$col] > $limit) {$count++; print "$_\n"} END {warn "Chose $count lines out of $.\n"}' infile > limited

Compare column values
perl -ne 'BEGIN {$colm=0; $coln=1;}' -e 's/\r?\n//; @F=split /\t/, $_; if ($F[$colm] eq $F[$coln]) {print "$_\n"}' infile > outfile

Delete first 'n' lines
perl -ne 'BEGIN {$del_lines=1;}' -e 'if ($. > $del_lines) {print $_}' infile > outfile

Remove Dup lines
perl -ne 'BEGIN {$unique=0}; if (!($save{$_}++)) {print $_; $unique++} END {warn "Chose $unique unique lines out of $. total lines.\n"}' genes > unique

perl -ne 'BEGIN {$column = 0}' -e 'BEGIN {$unique=0}; s/\r?\n//; @F=split /\t/, $_; if (!($save{$F[$column]}++)) {print "$_\n"; $unique++} END {warn "Chose $unique unique lines out of $. total lines\nRemoved duplicates in column $column.\n"}' hits > unique_hits

Like EFetch
perl -MLWP::Simple -e '$web_file = "ftp://ftp.ncbi.nih.gov/genbank/GB_Release_Number"; $store = "GB.txt";' -e 'if (is_success(getstore($web_file, $store))) { warn "Downloaded $web_file into $store\n"; } else {warn "Error downloading $web_file\n"}'

Merge
Union
All lines appearing in either input file will be printed. The lines will be printed in the order they appear in the first file, followed by the order of lines in the second file.
Note: Even if a line appears more than once in a file, or appears in both files, it will be printed only once. (Having the same first column in tabular data is not the same as being a duplicate.)

perl -ne 'if (!($save{$_}++)) {print $_}' file1 file2 > merged

Intersect
Any line that appears in the first file and also appears in the second file will be printed. The lines will be printed in the order they appear in the first file.

perl -e '($file1, $file2) = @ARGV; open F2, $file2; while (<F2>) {$h2{$_}++}; open F1, $file1; while (<F1>) {if ($h2{$_}) {print $_; $h2{$_} = ""}}' file1 file2 > intersection

Unique
All lines that appear in first file or in the second file, but not in both, will be printed. The lines from the first file will be printed (in the order they appear) followed by the lines in the second file.

perl -e '($file1, $file2) = @ARGV; open F2, $file2; while (<F2>) {$h2{$_}=1} open F1, $file1; while (<F1>) {if (exists $h2{$_}) {delete $h2{$_}} else {$h1{$_}=1}} END {print join("", keys(%h1), keys(%h2))}' xor1 xor2 > not_shared

Unique to File 1
All lines that appear in first file but not in the second file will be printed. (Make sure to give the files in the correct order!) The lines will be printed in the order they appear in the (first) file.

Merge by shared column
Join tables in tab-separated files file1 and file2. For all lines where the mth column in file 1 equals the nth column in file2, print the line from file1, a tab, and the line from file2. This operation is similar to a SQL join.

perl -e '$col1=1; $col2=0;' -e '($f1,$f2)=@ARGV; open(F1,$f1); while (<F1>) {s/\r?\n//; @F=split /\t/, $_; $line1{$F[$col1]} .= "$_\n"}; warn "\nJoining $f1 column $col1 with $f2 column $col2\n$f1: $. lines\n"; open(F2,$f2); while (<F2>) {s/\r?\n//; @F=split /\t/, $_; $x = $line1{$F[$col2]}; if ($x) {$x =~ s/\n/\t$_\n/g; print $x; $merged++}} warn "$f2: $. lines\nMerged file: $merged lines\n";' ortho.tab human_func.tab > fly_func.tab

Like FGrep
Given a list of gene names and a tab-separated table of annotations, take only the lines where the fourth column has names from the list. Simply treat the list as a table with only one column. That is:

perl -e '$col1=0; $col2=3;' -e '...' gene_names.list all_annot.tab > some_annot.tab

Word Freq Count
perl -wlne'/^(\S+)/;$h{$1}++}{print"$h{$_}\t$_"for sort{$h{$a}<=>$h{$b}}keys%h' file

-or rev sort- 
perl -wlne'/^(\S+)/;$h{$1}++}{print"$h{$_}\t$_"for sort{$h{$b}<=>$h{$a}}keys%h' file