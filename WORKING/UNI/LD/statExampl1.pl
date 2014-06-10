#########################################################################
#                                                                       # 
#    Parse GenePix 4.0 GPR Files                                        #
#                                                                       #
#    This script takes the tab-delimited output files (*.gpr) from      #
#    GenePix and uses a combination of the diameter and intensity       #
#    values measured for each colony to assign a trinary value          #
#    that represents its relative growth.                               #
#                                                                       #
#    On each plate, only a small subset of the colonies are expected    #
#    to deviate from wild-type growth. Therefore the average diameter   #
#    and intensity measurements for all the colonies on a plate         #
#    approximates wild-type growth for that plate.                      #
#                                                                       #
#    Colonies that differ from the average by set standard deviations   #
#    are assigned a value of "0" for non-growth and a value of "1"      #
#    for slow growth. Wild-type colonies are assigned a value of "2"    #    
#                                                                       #                     
#    Updated 7/30/02                                                    #
#    Daniel Janse                                                       #
#                                                                       #
#########################################################################


#Growth values are assigned based on threshold values of two statistics: 
#colony diameter and colony mean pixel intensity. The mean and SD values are 
#calculated for each plate (excluding colonies that are flagged as EMPTY by
#by GenePix).
#Growth values are assigned based on thresholds generated by the number
#SDs below the mean values. 

#This script uses the CPAN Statistics_Descriptive package
use Statistics::Descriptive;
    
#assign the number of standard deviations to define a threshold
#for diameter and intensity values. Thresholds are assigned based
#on manual classification of 4000 colonies. 
$dthresh1=1;
$dthresh2=3;

$ithresh1=1;
$ithresh2=2.5;

#Define the two output files, one is for the processed data and one
#for the extracted raw diameter and intensity data
$output_file = "384KO_output.txt";
$output_file2 = "384KO_output2.txt"; 

#Find and read the data sets to be analyzed
#Some data from plate 7 on the 384-well plates was corrupted. This was
#corrected by reprinting plate 28 from the orginal 96-well library

opendir RESULTS, "f:/Share/SyntheticKO/Results/384Well/";
opendir RESULTS2, "f:/Share/SyntheticKO/Results/plate28s/";
@unsortedfilename = grep !/^(/./.?|Old)/, readdir RESULTS;
@unsortedfilename28 = grep !/^(/./.?|Old)/, readdir RESULTS2;
@filename = sort {lc($a) cmp lc($b)} @unsortedfilename;
@filename28 = sort {lc($a) cmp lc($b)} @unsortedfilename28;

#Setup Output File. This is intially transposed to facilitate ease of adding results
 system ("copy c:///"Documents and Settings/"//janse.GENETICS.000//Desktop//384KO2.txt c:///"Documents and Settings/"//janse.GENETICS.000//Desktop//384KO_out.txt");

$location = "384Well";
$location28 = "plate28s";

&parse_gpr(/@filename, $location, 13, $output_file);
&parse_gpr(/@filename28, $location28, 1, $output_file2);




#########################################
#                                       #
#    Subroutine for assigning trinary   #
#    growth values to colony            #
#                                       #
#########################################


sub parse_gpr {
    my ($aref, $loc, $loc2, $toggle, $file, $outputfile);
    
#Read in the condition filenames, locations, number of plates per set, output filename) 
($aref, $loc, $toggle, $outputfile) = @_; 
    
#Cycle through all the different conditions and print them in the output file as headers
    for $x (0..$#$aref) {
	$loc2 = "f:/Share/SyntheticKO/Results/$loc/$$aref[$x]";
	open OUTPUT, ">>c:/Documents and Settings/janse.GENETICS.000/Desktop/384KO_out.txt" or die "Cannot open output";
	print OUTPUT "$$aref[$x]/t";
	
#Go through all the plates in each condition and initialize the diameter and intensity variables
#toggle==13 refers to the 13 384 well plates. When toggle==1 the extra plate 28 is run

	for ($file=1; $file<=$toggle; $file++) {
	    $diameter_stat = Statistics::Descriptive::Full->new();
	    $intensity_stat = Statistics::Descriptive::Full->new();
	    if($toggle==13) {
		open FILE,  "$loc2/$filename[$x]-$file.txt" or die "Cannot open $loc2/$filename[$x]-$file.txt";
	    }
	    else { open FILE, "$loc2" or die "Cannot open $loc2";}
	    @lines = <FILE>;
	    
#Read in the lines of the file, push the diameter into a diameter array and push 
#the intensity into an intensity array. If the colony is not flagged as empty
#use diameter and intensity values in calculation of mean and SD. Intensity values
#are in different columns for even and odd plates due to the red/green assignment.
#Also add a flag array
	    
	    for $i (0..$#lines) {
		if ($lines[$i] =~ /^/d+/t/d+/t/d+/t/"/"/t/S+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/t/d+/) {
		    @array=split//t/, $lines[$i];
		    $diameter[$d]=$array[7];              
		    $flag[$d]=$array[80];
		    $d++;
		    if($array[80]==0){
			$diameter_stat->add_data($array[7]);}
		    
		    if ($toggle==13 && $file%2==0) {
		    $intensity[$e]=$array[9];
		    $e++;
		    if($array[80]==0){
			$intensity_stat->add_data($array[9]);}
		}
		    
		else {		 
		    $intensity[$e]=$array[18];
		    $e++;
		    if($array[80]==0){
			$intensity_stat->add_data($array[18]);}
		}
		    @array="";
		}  
	    }
	    
#Get the mean and SD of  diameter size and intensities size, 
#not including the empty cells.
	    
	    $diameter_mean=$diameter_stat->mean();
	    $diameter_SD=$diameter_stat->standard_deviation();
	    
	    $intensity_mean=$intensity_stat->mean();
	    $intensity_SD=$intensity_stat->standard_deviation();
	    
#Define threshold values for each plate
	    $diameter_threshold1=$diameter_mean-$dthresh1*$diameter_SD;
	    $intensity_threshold1=$intensity_mean-$ithresh1*$intensity_SD;
	    
	    $diameter_threshold2=$diameter_mean-$dthresh2*$diameter_SD;
	    $intensity_threshold2=$intensity_mean-$ithresh2*$intensity_SD;
			    
#Assign a "0", "1", or "2" on cutoff values of diameter and intensity.  
	    for $x (0..$#intensity) {

		if($flag[$x]!=0 | $diameter[$x]<=40) 
		{print OUTPUT "0/t";}
		
		elsif($intensity[$x]<$intensity_threshold2 &&$diameter[$x]<$diameter_threshold1)
		{print OUTPUT "1/t";}
		
		elsif($intensity[$x]<$intensity_threshold1&&$diameter[$x]<$diameter_threshold2)
		{print OUTPUT "1/t";}
		
		else{print OUTPUT "2/t";}
	    }
	    
#Reset the diameter and intensity arrays
	    $d="";
	    $e=""; 
	    
	    close FILE;
	}    
	print OUTPUT "/n";
	close OUTPUT;
    }
    
    system ("transpose.pl 384KO_out.txt $outputfile");
    system ("del c:///"Documents and Settings/"//janse.GENETICS.000//Desktop//384KO_out.txt");
}
    







