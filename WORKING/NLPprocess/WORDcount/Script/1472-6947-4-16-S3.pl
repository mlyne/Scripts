#/usr/local/bin/perl -w
#doubcode.pl
#This script was created by Jules J. Berman on 06/15/04 and
#entered into the public domain.
#
#The software is provided "as is", without warranty of any kind,
#express or implied, including but not limited to the warranties
#of merchantability, fitness for a particular purpose and
#noninfringement. In no event shall the authors or copyright
#holders be liable for any claim, damages or other liability,
#whether in an action of contract, tort or otherwise, arising
#from, out of or in connection with the software or the use or
#other dealings in the software.
#
#As a courtesy, users of this script should cite the following
#article in all publications or software products that result from the
#use of the script.
#
#Berman JJ. Doublet method for very fast autocoding.
#Submitted, BMC Med Inform Decis Mak
#
open (TEXT,"neocl.xml")||die"Cannot";
my $line = " ";
my $count = 1;
#my $matchcount = 0;
my %doublinehash;
while ($line ne "")
  {
  $line = <TEXT>;
  $line =~ /\"(C[0-9]{7})\"/;
  $code = $1;
  $line =~ /\"\> ?(.+) ?\<\//;
  $phrase = $1;
  my $i;
  $phrase =~ s/\b([a-z]+oma)s/$1/g;
  $phrase =~ s/\b(tumo[u]?r)s/$1/g;
  if ($phrase !~ / /)
     {
     $literalhash{$phrase} = $code;
     next;
     }
  $literalhash{$phrase} = $code;
  @hoparray = split(/ /,$phrase);
  $phrasecodes = "";
  for ($i=0;$i<(scalar(@hoparray));$i++)
      {
      if (exists $doubhash{"$hoparray[$i] $hoparray[$i+1]"})
          {
          $phrasecodes = $phrasecodes . " ". $doubhash{"$hoparray[$i] $hoparray[$i+1]"};
          next;
          }
      if ($hoparray[$i+1] ne "")
         {
         $doubhash{"$hoparray[$i] $hoparray[$i+1]"}=$count;
         $phrasecodes = $phrasecodes . " ". $doubhash{"$hoparray[$i] $hoparray[$i+1]"};
         $count++;
         }
      }
  $phrasecodes =~ s/^ +//;
  $phrasecodes =~ s/ +$//;
  $phrasecodes =~ s/ +/ /g;
  $phrasehash{$phrasecodes} =$phrase;
  }
close TEXT;
#$/ = "*RECORD*"; #if we wanted to use OMIM
$/ = "\n\n";  #this sets the line separator.  For tumor.txt, it
              #happens to be a double newline (double return)
              #The default is a single newline, which is almost
              #never what you want, because a physical line is seldom
              #going to be a text record separator
$start = time();  #the timing really starts here.  all
                  #the preceding code was used to create the
                  #nomenclature hash as a prelude to aucoding.
                  #if you like, you can bypass the preceding code
                  #by working with an sdbm file that keeps the nomenclature
                  #in a persistent tiehash
#open (TEXT, "omim")||die"cannot";  #if we wanted to use OMIM
open (TEXT, "tumor.txt")||die"cannot";
#open (OUT, ">omim.out")||die"cannot"; #if we wanted to use OMIM
open (OUT, ">doub.out")||die"cannot";
my $lineholder = " ";
#my (@phrasearray);
while ($lineholder ne "")
   {
   my (@hoparray, $doublet, $i);
   my $doubline = "";
   $lineholder = <TEXT>;
   $line = $lineholder;
   #$line =~ s/\-\n//g;
   $line =~ s/\n/ /g;
   $line = lc($line);
   $line =~ s/\'[s]?//g;
   $line =~ s/\b([a-z]+oma)s/$1/g;
   $line =~ s/\b(tumo[u]?r)s/$1/g;
   $line =~ s/[^a-z 0-9\-]/ /g;
   $line = "the $line the";
   $line =~ s/ +/ /g;
   @hoparray = split(/ /,$line);
   for ($i=0;$i<(scalar(@hoparray)-1);$i++)
      {
      if (exists $literalhash{$hoparray[$i]})
         {
         $subhash{$hoparray[$i]} = "";#let's save the singlets
         #$matchcount++;
         }
      $doublet = "$hoparray[$i] $hoparray[$i+1]";
      if (exists $doubhash{$doublet})
          {
          if ($doubline ne "")
            {
            $doubline = $doubline . " $doubhash{$doublet}";
            }
          else
            {
            $doubline = $doubhash{$doublet};
            }
          }
      else
          {
          if ($doubline ne "")
             {
             $doublinehash{$doubline} = "";
             $doubline = "";
             }
          }
      }
   }
foreach $doubthing (keys %doublinehash)
  {
  &parser($doubthing);
  if (exists $phrasehash{$doubthing})
     {
     $subhash{"$phrasehash{$doubthing}"}="";
     #$matchcount++;
     }
   }
$end = time();
$totaltime = $end - $start;
print "\nThe time to code was $totaltime seconds\n";
#print "\nThe number of total matches was $matchcount\n";


sub parser
   {
   my (@fourwords, @hoparray, $i, $key);
   my $value = @_[0];
   @hoparray = split(/ /,$value);
   for ($i=0;$i<(scalar(@hoparray));$i++)
      {
      push(@fourwords, ("$hoparray[$i]", "$hoparray[$i] $hoparray[$i+1]",
      "$hoparray[$i] $hoparray[$i+1] $hoparray[$i+2]"));
      if (defined $hoparray[$i+3])
         {
         push(@fourwords,("$hoparray[$i] $hoparray[$i+1] $hoparray[$i+2] $hoparray[$i+3]",
         "$hoparray[$i] $hoparray[$i+1] $hoparray[$i+2] $hoparray[$i+3] $hoparray[$i+4]"));
         }
      }
   foreach my $key (@fourwords)
      {
      if (exists $phrasehash{$key})
        {
        $subhash{"$phrasehash{$key}"}="";
        #$matchcount++;
        }
      }
   }


 while ((my $key, my $value) = each(%subhash))
    {
    if ($key ne "")
      {
      print OUT "$key\n";
      }
    }

exit;
