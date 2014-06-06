#!/software/arch/bin/perl -w
#
#
#

use Date::Manip qw(ParseDate UnixDate);


sub date {
  my $line = shift;

  my $date = ParseDate($line);
  if (!$date) {
    warn "Incorrect date: $line\n";
    return;
  } else {
    my ($year, $month, $day) = UnixDate($date, "%Y", "%m", "%d");
    if ($year !~ /200/) { 
      warn "Incorrect date: $line\n"; 
      return;
    }
    my $newDate = "$year-$month-$day";
    return $newDate;
#    print "Date was $year-$month-$day\n";
  }
}

my $requestByDate;

print "e.g. first tuesday in october 2000
Enter a Date: ";
chomp($requestByDate = <STDIN>);
my $newDate;
$newDate = date($requestByDate);

while (! $newDate) {
  print "e.g. first tuesday in october 2000
Enter a Date: ";
  chomp($requestByDate = <STDIN>);
  $newDate = date($requestByDate);
}

print "$newDate\n";
