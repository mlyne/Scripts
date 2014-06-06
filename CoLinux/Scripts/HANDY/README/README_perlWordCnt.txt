Word Freq Count
perl -wlne'/^(\S+)/;$h{$1}++}{print"$h{$_}\t$_"for sort{$h{$a}<=>$h{$b}}keys%h' file

-or rev sort- 
perl -wlne'/^(\S+)/;$h{$1}++}{print"$h{$_}\t$_"for sort{$h{$b}<=>$h{$a}}keys%h' file