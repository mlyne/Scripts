#!/usr/bin/perl -w 
 
# Verify above line is correct for your server.
use strict;

my @date = localtime;


#$date[4]++;
#$date[5] += 1900;
#$date[5] = substr($date[5],2);

print "$date[2]\:$date[1]\:$date[0] on ";
print "$date[3]\/$date[4]\/$date[5]\n";

# end of practice script
