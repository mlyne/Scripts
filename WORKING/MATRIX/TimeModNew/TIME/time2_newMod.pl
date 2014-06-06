#!/usr/bin/perl -w

use DateTime;
use strict;

FILE_LOOP: while(<>) {
	
	Time_Check();
				
	print "\n", "doing something\n";
	print $_, "\n";
	sleep 3;		
}

sub Time_Check {
	
	#my $early = 1059; 
	#my $late = 1109; 
	
	my $early = "1000"; 
	my $late = "1100"; 
	
	
	my $t = DateTime->now;
	print $t->hms, "\n";
	print "today ", $t->hms, "\t", $t->dmy, "\n";
	my @ltime = split(/:/, $t->hms);
	my $hour = $ltime[0];
	my $time = "$ltime[0]$ltime[1]";
	print "hour ", $hour, "\n";

	my $dayNum = $t->wday;
	print "day ", $dayNum, "\n";

	if ($hour < 5) {
		$dayNum -= 1;
		print "day_ ", $dayNum, "\n";
	}

	unless (($dayNum < 2) || ($dayNum > 6)) {

		while ($time <= $early || $time >= $late) {
			print $time, ": time to sleep\n";
			sleep 3;
			
			$t = DateTime->now;
			@ltime = split(/:/, $t->hms);
			$time = "$ltime[0]$ltime[1]";
			$hour = $ltime[0];
			
		}
		
		$dayNum = $t->wday;
		if ($hour lt 5) {
			$dayNum -= 1;
		print $dayNum, "\n";
		}
	}
		
}
