#!/software/arch/bin/perl -w
#
#
#

use Date::Manip qw(ParseDate UnixDate);
use Time::localtime;
use strict;


my $tm = localtime;
my ($year, $month, $day);
$year = $tm->year+1900;
$month = ($tm->mon)+1;
$day = $tm->mday;
my $date = "$year-0$month-$day";

my ($requestType);
print STDERR "1 = FL_electronic
2 = FL_de_novo
3 = FL_current_reagent
4 = Lark
5 = Odyssey
6 = Galapagos_de_novo
7 = Galapagos_send
8 = Antibody
9 = Protein
15 = Update Reagent info
Reagent request Type: ";
chomp($requestType = <STDIN>);

if ($requestType) {
  ($requestType == 1) and FL_build(1);
  ($requestType == 2) and FL_build(2);
  ($requestType == 3) and FL_current_reagent();
  ($requestType == 4) and SendTo(1);
  ($requestType == 5) and SendTo(2);
  ($requestType == 7) and SendTo(3);
  ($requestType == 15) and UpDate();
}

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
#    print "Date was $month/$day/$year\n";
  }
}

sub FL_build {
  my $denovo = shift;
  my ($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
      $requestFromLab, $orderNumber, $receivedDate, $receivedBy) = Request();
  my $arrRef = Request_LociFile($denovo);
  my @locus = @{ $arrRef };
  my $reagent_track;
  for my $i (0 .. $#locus) {
    print "Locus : \"$locus[$i]\"\n";
    $reagent_track = "FL_elect_${locus[$i]}_$requestVers" if ($denovo == 1);
    $reagent_track = "FL_denovo_${locus[$i]}_$requestVers" if ($denovo == 2);
    print "FL_electronic       \"$reagent_track\"\n\n" if ($denovo == 1);
    print  "FL_de_novo       \"$reagent_track\"\n\n" if ($denovo == 2);
    PrintOut($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
	     $requestFromLab, $orderNumber, $receivedDate, $receivedBy, $reagent_track, $denovo);
    print  "Locus_FL_electronic       \"$locus[$i]\"\n\n" if ($denovo == 1);
    print  "Locus_FL_de_novo       \"$locus[$i]\"\n\n" if ($denovo == 2);
  }
}
  
sub FL_current_reagent {
  my ($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
      $requestFromLab, $orderNumber, $receivedDate, $receivedBy) = Request();
  my ($locus, $reagent);
  my $arrRef = Request_LociReagFile();
  my @arrRefs = @{ $arrRef };
  for my $i (0 .. $#arrRefs) {
    ($locus, $reagent) = @ {$arrRefs[$i] };
    print "Locus : \"$locus\"\n";
    my $reagent_track = "FLC_${reagent}_$requestVers";
    print  "FL_current_reagent       \"$reagent_track\"\n\n";
    PrintOut($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
	     $requestFromLab, $orderNumber, $receivedDate, $receivedBy, $reagent_track);
    print  "Locus_FL_current_reagent       \"$locus\"\n\n";
  }
}

sub Date_process {
  print STDERR "\neg. $date
or 'today' for today\'s date
Date Reagent sent (yyyy-mm-dd): ";
  chomp($date =  <STDIN>);
  my $newDate;
  $newDate = date($date);

  while (! $newDate) {
    print STDERR "e.g. first tuesday in october 2000
Enter a Date: ";
    chomp($date = <STDIN>);
    $newDate = date($date);
  }

  $date = $newDate;
  return $date
}


sub SendTo {
  my $lab = shift;
  my ($prefix, $person, $tag);
  if ($lab == 1) {
    $prefix = "LAR";
    $person = "Lammert Albers";
    $tag = "Lark";
  } elsif ($lab == 2) {
    $prefix = "ODY";
    $person = "Billy Fish";
    $tag = "Odyssey";
  } elsif ($lab == 3) {
    $prefix = "GAL";
    $person = "Albert Ross";
    $tag = "Galapagos";
  }
  
  my $sentDate;
  $sentDate = Date_process();

  my ($locus, $reagent);
  my $arrRef = Request_LociReagFile();
  my @arrRefs = @{ $arrRef };
  for my $i (0 .. $#arrRefs) {
    ($locus, $reagent) = @{ $arrRefs[$i] };
    print "Locus : \"$locus\"\n";
    my $reagent_track = "${prefix}_$reagent";
    print  "$tag       \"$reagent_track\"\n\n";
    print  "Reagent_track : \"$reagent_track\"\n";
    print  "Supplied_to      \"$person\" $sentDate\n";
    print  "Locus_$tag       \"$locus\"\n\n";
  }
}

sub UpDate {
  my ($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
      $requestFromLab, $orderNumber, $receivedDate, $receivedBy) = Request(1);
  my ($locus, $reagent_trackID);
  my $arrRef = Request_LociReagFile();
  my @arrRefs = @{ $arrRef };
  for my $i (0 .. $#arrRefs) {
    ($locus, $reagent_trackID) = @{ $arrRefs[$i] };
    my $reagent_track = $reagent_trackID;
    print "\n\n";
    PrintOut($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
	     $requestFromLab, $orderNumber, $receivedDate, $receivedBy, $reagent_track);
  }
}

sub Galapagos {
}

sub Antibody {
}

sub Protein {
}

sub Request_LociFile {
  my $denovo = shift;
  print STDERR "\nFile of Loci: ";
  my $arrRef = inFile($denovo);
  return $arrRef;
}

sub Request_LociReagFile {
  print STDERR "Tab delimited file containing Loci and Reagent_ids: ";
  my $arrRef = inFile();
  return $arrRef;
}

sub Request {

  my $update = shift;

  my ($requestBy, $requestByDate);
  my ($requestVers);
  my ($requestFrom, $requestFromDate);
  my ($requestFromLab);
  my ($orderNumber);
  my ($receivedDate, $receivedBy);

  print STDERR "\n1 = Mike Lyne
2 = Ines Barroso
3 = Alan Schafer
Reagent requested by: ";
  chomp($requestBy = <STDIN>);
  ($requestBy !~ /[1-3]/) and warn "Skipping Reagent request info.\n";

  if ($requestBy) {
    if ($requestBy == 1) { $requestBy = "Mike Lyne" }
    elsif ($requestBy == 2) { $requestBy = "Ines Barroso" }
    elsif ($requestBy == 3) { $requestBy = "Alan Schafer" }
    else { undef($requestBy) }

    $requestByDate = Date_process();
  }

  unless ($update) {
    print STDERR "\nRequest version (1-10): ";
    chomp($requestVers = <STDIN>);
    while (! $requestVers) {
      print STDERR "\nYou need to supply a version number for new requests!
If you're updating, use option 15 \;\-\)\n
Request version (1-10): ";
      chomp($requestVers = <STDIN>);
    }
  }

  print STDERR "\n1 = Lynne Porter
2 = Don Morris
3 = Mike Rose
4 = Sam Labrie
Reagent requested from: ";
  chomp($requestFrom = <STDIN>);
  ($requestFrom !~ /[1-4]/) and warn "Skipping Requested From info.\n";
  if ($requestFrom) {
    if ($requestFrom == 1) {$requestFrom = "Lynne Porter"}
    elsif ($requestFrom == 2) {$requestFrom = "Don Morris"}
    elsif ($requestFrom == 3) {$requestFrom = "Mike Rose"}
    elsif ($requestFrom == 4 ) {$requestFrom = "Sam Labrie"}
    else { undef($requestFrom) }

    $requestFromDate = Date_process();
      
    print STDERR "\n1 = CTG
2 = PA_bioinf
3 = NDAC
4 = Galapagos
5 = Lexicon
6 = Research Genomics
Laboratory Reagent requested from: ";
    chomp($requestFromLab = <STDIN>);
    ($requestFromLab !~ /[1-6]/) and warn "Skipping Lab info\n";
    if ($requestFromLab == 1) { $requestFromLab = "CTG" }
    elsif ($requestFromLab == 2) { $requestFromLab = "PA_bioinf" }
    elsif ($requestFromLab == 3) { $requestFromLab = "NDAC" }
    elsif ($requestFromLab == 4) { $requestFromLab = "Galapagos" }
    elsif ($requestFromLab == 5) { $requestFromLab = "Lexicon" }
    elsif ($requestFromLab == 6) { $requestFromLab = "Research Genomics" }
    else { undef($requestFromLab) }
  }

  print STDERR "\neg. 01214T3945
Order Number: ";
  chomp($orderNumber = <STDIN>);

#  ($receivedDate !~ /\d{4}\-\d{2}\-\d{2}/) and die "\nDate type must be yyyy-mm-dd!\n" 
#      unless ( (! $receivedDate) or ($receivedDate eq "today") );
#  $receivedDate = $date if ( ($receivedDate) and ($receivedDate eq "today") );

  print STDERR "\n1 = Mike Lyne
2 = Ines Barroso
3 = Alan Schafer
4 = Craig Luccarini
Reagent received by: ";
  chomp($receivedBy = <STDIN>);
  ($receivedBy !~ /[1-4]/) and warn "Skipping Reagent Received info\n";
  if ($receivedBy) {
    if ($receivedBy == 1) { $receivedBy = "Mike Lyne" }
    elsif ($receivedBy == 2) { $receivedBy = "Ines Barroso" }
    elsif ($receivedBy == 3) { $receivedBy = "Alan Schafer" }
    elsif ($receivedBy == 4) { $receivedBy = "Craig Luccarini" }
    else { undef($receivedBy) }

    $receivedDate = Date_process();
  }

  return ($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, 
	  $requestFromLab, $orderNumber, $receivedDate, $receivedBy);

}

sub inFile {
  my $denovo = shift;
  my $LocReagFile;
  my @array = ();
  
  chomp($LocReagFile = <STDIN>);

  $LocReagFile || die "\nOOOPS!\nYou must supply a Tab delimited file containing Loci and Reagent_ids!
or a file of Loci for \"de novo\" reagents!\n";

  if (-r $LocReagFile) {
    open(INFILE, "< $LocReagFile") or die "Can't open $LocReagFile: $!\n";
  } else {
    die "File \"$LocReagFile\" does not exist!\n";
  }

  while (<INFILE>) {
    chomp;
    if ($denovo) {
      push @array, $_;
    } else {
      my ($locus, $reagent) = split("\t", $_);
      push @array, [$locus, $reagent];
    }
  }

  close(INFILE) or die "Can't close $LocReagFile: $!\n";
  
  return \@array;

}

sub PrintOut {

  my ($requestBy, $requestByDate, $requestVers, $requestFrom, $requestFromDate, $requestFromLab, 
      $orderNumber, $receivedDate, $receivedBy, $reagent_track, $denovo) = @_;

  print  "Reagent_track : \"$reagent_track\"\n";
  print  "Requested_by     \"$requestBy\" $requestByDate\n" if ($requestBy);
  print  "Requested_from   \"$requestFrom\" $requestFromDate\n" if ($requestFrom);
  print  "Requested_lab    \"$requestFromLab\"\n" if ($requestFrom);
  print  "Order_no         \"$orderNumber\"\n" if ($orderNumber);
  print  "de_novo\n" if ($denovo);
  print  "Received         $receivedDate \"$receivedBy\"\n" if ($receivedDate);

}
