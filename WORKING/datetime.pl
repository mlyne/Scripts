#!/usr/bin/perl -w

use DateTime;

my $stamp = DateTime->now( time_zone => 'Europe/London' );
print "# ", $stamp->dmy, "\t", $stamp->hms, "\n";

#my $count;

#Foreach ($count) {
#}

# Check the time ###
Time_Check(); ### take out for testing

### Subroutines ####
###  Time_Check  ###

sub Time_Check {
   
        my $early = "2100"; 
        my $late = "0203"; 


	my$locTime = localtime();
	print "Local Time: ", $locTime, "\n";
        
        my $t = DateTime->now( time_zone => 'America/New_York' );
        print $t->hms, "\n";

        my @ltime = split(/:/, $t->hms);
        my $hour = $ltime[0];
	# *** $hour +=4; # Fiddle factor to get over the midnight bridge
	my $min = $ltime[1];
	my $time = "$hour$min";
        #my $time = "$ltime[0]$ltime[1]";
	#print "time ", $time, "\n";
        #print "hour ", $hour, "\n";

        my $dayNum = $t->wday; # 1-7 (Monday is 1) - 
        print "day ", $dayNum, " (Monday is 1)\n";

        unless (($dayNum < 2) || ($dayNum > 5)) {

                while ($time <= $early && $time >= $late) {
                        print $t->hms, " Eastern Time: time to sleep ($time)\n";
                        sleep 10;
                        
                        $t = DateTime->now( time_zone => 'America/New_York' );
        		@ltime = split(/:/, $t->hms);
        		$hour = $ltime[0];
			# *** $hour +=4; # Fiddle factor to get over the midnight bridge
			$min = $ltime[1];
			$time = "$hour$min";
                        
                }

        }
                
}


