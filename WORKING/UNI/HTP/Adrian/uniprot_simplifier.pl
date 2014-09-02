#!/usr/bin/perl

$filename = $ARGV[0];

@line_ids = qw(ID AC DT DE GN OS OC DR);
open $FILEA, "< $filename";
while(<$FILEA>) {
$line_id = substr($_,0,2);
if (grep(/$line_id/, @line_ids) ){
print $_;
}
        
}

