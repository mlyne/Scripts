package TimeCheck;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Time_Check);

use DateTime;
use strict;

# Check the time ###
# called with: Time_Check(); ### take out for testing

sub Time_Check {
        
        my $early = "2100";
	my $late = "0500";
        #my $late = "0220"; 

	my$locTime = localtime();
	print "Local Time: ", $locTime, "\n";
        
        my $t = DateTime->now( time_zone => 'America/New_York' ); # Change zone to Eastern Time
        print $t->hms, " : Eastern Time\n";

        my @ltime = split(/:/, $t->hms);
        my $hour = $ltime[0];
	#$hour +=4; # Fiddle factor to get over the midnight bridge
	my $min = $ltime[1];
	my $time = "$hour$min";
        #my $time = "$ltime[0]$ltime[1]";
	#print "time ", $time, "\n";
        #print "hour ", $hour, "\n";

        my $dayNum = $t->wday; # 1-7 (Monday is 1) - 
        print "day ", $dayNum, " (Monday is 1)\n";

        #unless (($dayNum < 2) || ($dayNum > 5)) {
	unless ( $dayNum > 5 ) {

                while ($time <= $early && $time >= $late) {
                        print $t->hms, " Eastern Time: time to sleep ($time)\n";
                        sleep 60;
                        
                        $t = DateTime->now( time_zone => 'America/New_York' );
        		@ltime = split(/:/, $t->hms);
        		$hour = $ltime[0];
			#$hour +=4; # Fiddle factor to get over the midnight bridge
			$min = $ltime[1];
			$time = "$hour$min";
                        
                }
	#$dayNum = $t->wday; # 1-7 (Monday is 1)
        }
                
}
1;