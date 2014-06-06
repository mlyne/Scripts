#/usr/local/bin/perl
# Program Name: parsemedline.pl
#
# AUTHOR: Diane E. Oliver
# DATE: Jan. 20, 2004
#
# COPYRIGHT by Diane E. Oliver 2004
#
# This program reads in Medline data from one XML file and writes
# out data to either a set of flat files in tabular format, or
# or to a relational database directly.
#
# Perl version recommended: Perl 5.8 (handles Unicode)
# Perl modules required (available at http://www.cpan.org):
#   1. DBI (including appropriate database driver such as DBD:Oracle)
#   2. XML::Parser::PerlSAX
#
# Input:
# The user can enter input parameters at the command line when
# prompted. For example, type:
#  "perl parsemedline.pl" (and then respond to prompts)
# Alternatively, the user can include input parameters
# in the argument list. For example, if output is going directly
# to the database, type:
#  "perl parsemedline.pl testfile.xml error log sizes db"
# Or if output is to be written to a flat file and it is the
# first file to be processed (i.e. new table files are being created,
# type:
#  "perl parsemedline.pl testfile.xml error log sizes flatfile new"
# Or if this is not the first file in a set to be processed and the
# output data should be appended to the existing table files, type:
#  "perl parsemedline.pl testfile.xml error log sizes flatfile append"
#
# Input parameters:
# (1) input file name
# (2) error file name
# (3) log file name
# (4) "sizes" or "nosizes"
# (5) "db" or "flatfile"
# (6) "new" or "append"
# (7) user
# (8) password
#
# Explanation of input parameters:
# (1) input file name: This parameter is the name of the Medline
#     XML input file. Either the relative path name or the full path
#     name should work. The file handle used for this file is INPUTFILE.
# (2) error file name: This parameter is the name of the error file
#     that is generated. It can be used by developers for debugging.
#     There is a statement in sub start_element() that can be 
#     uncommented to track the elements in the input file as they 
#     are being processed. If processing is interrupted, the developer 
#     can determine where the problem occurred by reviewing the error 
#     file. In addition, there are print statements at the end of 
#     each print subroutine that states that the subroutine is finishing.
#     These print statements are commented out with "######".
#     The only other information recorded in this file occurs in
#     sub start_document, where start and stop time are recorded.
#     The filehandle used for this file is ERRORFILE. This file is 
#     not STDERR. 
# (3) log file name - This parameter is the name of the log file
#     The log file records information about the input file, and
#     data such as start and stop time, and time taken to process
#     the file. Optionally, data on the sizes of the files or the
#     number of rows in the table so far are included in this file.
#     (See sizes/nosizes parameter.) The file handle used for this 
#      file is LOGFILE.
# (4) sizes or nosizes - The user sets this parameter to "sizes" or
#     "nosizes" to specify whether the log file should
#     include information on the sizes of files being produced or
#     not. If "sizes" is selected, the resulting log file is
#     much larger. If data are being written to flat files, then
#     the size information is the number of bytes in each file so
#     far. If data are being written directly to the database, then
#     the number of rows in each table so far is recorded.
# (5) db or flatfile - The user sets this parameter to specify whether 
#     data are to be written to the database directly ("db") or to a 
#     flat file ("flatfile").
# (6) new or append - This parameter indicates whether the file to be
#     process is the first of a series of input files to be processed 
#     ("new"), or not the first file to be processed ("append") 
#     Note that this parameter is ONLY included if the previous 
#     db/flatfile parameter was specified as "flatfile.")
# (7) username - This parameter is the username for accessing the 
#     database. Note that this parameter is ONLY included if the
#     previous db/flatfile parameter is set to "db".
# (8) password - This parameter is the password that goes with the
#     username for accessing the database.
#
# Output:
# If "flatfile" is selected, flat files are automatically written to
# a subdirectory in the current directory called "MedlineTables".
# See variable named $outputDirectoryPathForFlatFiles.
# The format of the flat files is tabular, with commas used as
# delimiters between fields, double vertical bars to mark the beginning
# and end of a field, and a space between fields.
#
# If "db" is selected, the database connection is specified by a
# host, sid, and port, and a username and password are required.
# Currently, host, sid, and port are hardcoded, and must be
# modified whenever the database changes. Username and password
# are user inputs.
# 

# The following statement is required to handle Unicode (UTF-8) 
# because Medline input files contain UTF-8 characters. This
# statement is recognized by Perl 5.8.
#use open ':utf8'; #input and output default layer will be UTF-8

# Use the standard Perl database interface module DBI. Also, be sure
# the appropriate database driver is included in your installation
# (e.g., DBD::Oracle, DBD::ODBC, or DBD::mysql).
use DBI;

# The following parameters are used when the database handle is
# created. See statement below that begins
#   "$main::dbh = DBI->connect ..."
# Replace hardcoded values below $main::host, $main::sid, and $main::port
# with host, sid, and port for your particular database.
# Leave $main::dbh blank (empty string) because it is set later.
# Leave $main:: user and $main::password blank because the
# the user will set these as input parameters at the command
# line or as arguments when the program is run.

$main::dbh = "";
$main::host = "dummy_host_name";
$main::sid = "dummy_sid";
$main::port = "dummy_port_number";
$main::username = "";
$main::password = "";

# These parameters correspond to the input parameters entered at
# the command line or as arguments when the program is run.
$main::inputFileName = "";
$main::errorFileName = "";
$main::logFileName = "";
$main::printSizes = "";
$main::dbOrFlatfile = "";
$main::newOrAppend = "";
$main::user = "";
$main::password = "";

$main::docTypeName = "";
$main::dtdPublicId = "";
$main::dtdSystemId = "";

# Declare file-level lexically scoped variables that are global 
# to the file so they can be used by the package MedlinePerlSAXHandler.
# "My" variables are more efficient than package variables. Must 
# declare and initialize them at the file level.

# Set path for output directory for flat-file output.
mkdir("MedlineTables", 0777);
my $outputDirectoryPathForFlatFiles = "MedlineTables";

my @elementStack = ();                  
my $currentElement= "";
my $text= "";              
my $elementNumber = 0;  

my $errorInFile = 0;
my $errorErrorFile = 0;
my $errorLogFile = 0;
my $errorPrintSizes = 0;
my $errorDBOrFlatFile = 0;
my $errorNewOrAppend = 0;

# More file-level lexically scoped variables: XML variables that store PCDATA. 
# These are the variables that represent XML ELEMENTS that store PCDATA. 
# We call these variables the XML element variables.
#
# The names of these variables are generally determined by the ELEMENT
# names in the DTD. Nested ELEMENTs result in variable names whose parts
# correspond to ELEMENTS and are connected by underscores. (If an
# ELEMENT has an ATTLIST, then the name of an attribute also is used to
# create a variable name.)

my @MedlineCitationSet_MedlineCitation_PMID = ();
my @MedlineCitationSet_DeleteCitation_MedlineID = ();
my @MedlineCitationSet_DeleteCitation_PMID = ();

my $MedlineCitation_MedlineID = "";
my $MedlineCitation_PMID = "";
my $MedlineCitation_DateCreated_Year = "";
my $MedlineCitation_DateCreated_Month = "";
my $MedlineCitation_DateCreated_Day = "";
my $MedlineCitation_DateCreated_Hour = "";
my $MedlineCitation_DateCreated_Minute= "";
my $MedlineCitation_DateCreated_Second = "";
my $MedlineCitation_DateCompleted_Year = "";
my $MedlineCitation_DateCompleted_Month = "";
my $MedlineCitation_DateCompleted_Day = "";
my $MedlineCitation_DateCompleted_Hour = "";
my $MedlineCitation_DateCompleted_Minute = "";
my $MedlineCitation_DateCompleted_Second = "";
my $MedlineCitation_DateRevised_Year = "";
my $MedlineCitation_DateRevised_Month = "";
my $MedlineCitation_DateRevised_Day = "";
my $MedlineCitation_DateRevised_Hour = "";
my $MedlineCitation_DateRevised_Minute = "";
my $MedlineCitation_DateRevised_Second = "";

my $MedlineCitation_KeywordList_Owner = "";
my $MedlineCitation_Owner = "";
my $MedlineCitation_Status = "";

my $MedlineCitation_MedlineJournalInfo_Country = "";
my $MedlineCitation_MedlineJournalInfo_MedlineTA = "";
my $MedlineCitation_MedlineJournalInfo_NlmUniqueID = "";

my @MedlineCitation_ChemicalList_Chemical_RegistryNumber = ();
my @MedlineCitation_ChemicalList_Chemical_NameOfSubstance = ();

my @MedlineCitation_CitationSubset = ();

my @MedlineCitation_CommentsCorrections_CommentOn_RefSource = ();
my @MedlineCitation_CommentsCorrections_CommentIn_RefSource = ();
my @MedlineCitation_CommentsCorrections_ErratumIn_RefSource = ();
my @MedlineCitation_CommentsCorrections_ErratumFor_RefSource = ();
my @MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource = ();
my @MedlineCitation_CommentsCorrections_RepublishedIn_RefSource = ();
my @MedlineCitation_CommentsCorrections_RetractionOf_RefSource = ();
my @MedlineCitation_CommentsCorrections_RetractionIn_RefSource = ();
my @MedlineCitation_CommentsCorrections_UpdateIn_RefSource = ();
my @MedlineCitation_CommentsCorrections_UpdateOf_RefSource = ();
my @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource = ();
my @MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource = ();

my @MedlineCitation_CommentsCorrections_CommentOn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_CommentIn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_ErratumIn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_ErratumFor_MedlineID = ();
my @MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID = ();
my @MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_RetractionOf_MedlineID = ();
my @MedlineCitation_CommentsCorrections_RetractionIn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_UpdateIn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_UpdateOf_MedlineID = ();
my @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID = ();
my @MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID = ();

my @MedlineCitation_CommentsCorrections_CommentOn_PMID = ();
my @MedlineCitation_CommentsCorrections_CommentIn_PMID = ();
my @MedlineCitation_CommentsCorrections_ErratumIn_PMID = ();
my @MedlineCitation_CommentsCorrections_ErratumFor_PMID = ();
my @MedlineCitation_CommentsCorrections_RepublishedFrom_PMID = ();
my @MedlineCitation_CommentsCorrections_RepublishedIn_PMID = ();
my @MedlineCitation_CommentsCorrections_RetractionOf_PMID = ();
my @MedlineCitation_CommentsCorrections_RetractionIn_PMID = ();
my @MedlineCitation_CommentsCorrections_UpdateIn_PMID = ();
my @MedlineCitation_CommentsCorrections_UpdateOf_PMID = ();
my @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID = ();
my @MedlineCitation_CommentsCorrections_OriginalReportIn_PMID = ();

my @MedlineCitation_CommentsCorrections_CommentOn_Note = ();
my @MedlineCitation_CommentsCorrections_CommentIn_Note = ();
my @MedlineCitation_CommentsCorrections_ErratumIn_Note = ();
my @MedlineCitation_CommentsCorrections_ErratumFor_Note = ();
my @MedlineCitation_CommentsCorrections_RepublishedFrom_Note = ();
my @MedlineCitation_CommentsCorrections_RepublishedIn_Note = ();
my @MedlineCitation_CommentsCorrections_RetractionOf_Note = ();
my @MedlineCitation_CommentsCorrections_RetractionIn_Note = ();
my @MedlineCitation_CommentsCorrections_UpdateIn_Note = ();
my @MedlineCitation_CommentsCorrections_UpdateOf_Note = ();
my @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_Note = ();
my @MedlineCitation_CommentsCorrections_OriginalReportIn_Note = ();

my @MedlineCitation_GeneSymbolList_GeneSymbol= ();

my @MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName = ();
my @MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName_MajorTopicYN = ();
my @MedlineCitation_MeshHeadingList_MeshHeading_QualifierName = (); #2d array
my @MedlineCitation_MeshHeadingList_MeshHeading_QualifierName_MajorTopicYN = (); #2d array

my $MedlineCitation_NumberOfReferences = "";

my @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName = ();
my @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_ForeName = ();
my @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_FirstName = ();
my @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_MiddleName = ();
my @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Initials = ();
my @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Suffix = ();

my @MedlineCitation_OtherID = ();
my @MedlineCitation_OtherID_Source = ();
my @MedlineCitation_OtherAbstract_AbstractText = ();
my @MedlineCitation_OtherAbstract_CopyrightInformation = ();
my @MedlineCitation_OtherAbstract_Type = ();
my @MedlineCitation_KeywordList_Keyword = ();
my @MedlineCitation_KeywordList_Keyword_MajorTopicYN = ();
my @MedlineCitation_SpaceFlightMission = ();

my @MedlineCitation_InvestigatorList_Investigator_LastName = ();
my @MedlineCitation_InvestigatorList_Investigator_ForeName = ();
my @MedlineCitation_InvestigatorList_Investigator_FirstName = ();
my @MedlineCitation_InvestigatorList_Investigator_MiddleName = ();
my @MedlineCitation_InvestigatorList_Investigator_Initials = ();
my @MedlineCitation_InvestigatorList_Investigator_Suffix = ();
my @MedlineCitation_InvestigatorList_Investigator_Affiliation = ();

my @MedlineCitation_GeneralNote = ();
my @MedlineCitation_GeneralNote_Owner = ();

my $Article_AuthorList_CompleteYN = "";
my $Article_DataBankList_CompleteYN = "";
my $Article_GrantList_CompleteYN = "";

my $Article_ArticleTitle = "";
my $Article_Pagination_StartPage = "";
my $Article_Pagination_EndPage = "";
my $Article_Pagination_MedlinePgn = "";

my $Article_Abstract_AbstractText = "";
my $Article_Abstract_CopyrightInformation = "";

my $Article_Affiliation = "";

my @Article_AuthorList_Author_LastName = ();
my @Article_AuthorList_Author_ForeName = ();
my @Article_AuthorList_Author_FirstName = ();
my @Article_AuthorList_Author_MiddleName = ();
my @Article_AuthorList_Author_Initials = ();
my @Article_AuthorList_Author_Suffix = ();
my @Article_AuthorList_Author_CollectiveName = ();
my @Article_AuthorList_Author_Affiliation = ();

my @Article_Language = ();

my @Article_DataBankList_DataBank_DataBankName = ();
my @Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber = (); # 2d array

my @Article_GrantList_Grant_GrantID = ();
my @Article_GrantList_Grant_Acronym = ();
my @Article_GrantList_Grant_Agency = ();

my @Article_PublicationTypeList_PublicationType = ();

my $Article_VernacularTitle = "";
my $Article_DateOfElectronicPublication = "";

my $Article_Journal_ISSN = "";
my $Article_Journal_JournalIssue_Volume = "";
my $Article_Journal_JournalIssue_Issue = "";
my $Article_Journal_JournalIssue_PubDate_Year = "";
my $Article_Journal_JournalIssue_PubDate_Month = "";
my $Article_Journal_JournalIssue_PubDate_Day = "";
my $Article_Journal_JournalIssue_PubDate_Season = "";
my $Article_Journal_JournalIssue_PubDate_MedlineDate = "";
my $Article_Journal_Coden = "";
my $Article_Journal_Title = "";
my $Article_Journal_ISOAbbreviation = "";
 
#The following index variables are indexes associated with tables 
#generated for the elements listed in %elementsTrackIndex                    
my $chemical_i = -1;
my $commenton_i = -1;
my $commentin_i = -1;
my $erratumin_i = -1;
my $erratumfor_i = -1;
my $repubfrom_i = -1;
my $repubin_i = -1;
my $retractof_i = -1;
my $retractin_i = -1;
my $updatein_i = -1;
my $updateof_i = -1;
my $summaryin_i = -1;
my $origreport_i = -1;
my $descname_i = -1;
my $qualname_i = -1;
my $personalsub_i = -1;
my $otherab_i = -1;
my $investigator_i = -1;
my $articleauthor_i = -1;
my $grant_i = -1;
my $keyword_i = -1;
my $otherid_i = -1;
my $gennote_i = -1;

#Create a hash of elements that have attributes. If we make a hash, we
#can use the exists function for hash arrays to see if an element is in
#this set. The ELEMENTS that have ATTLISTs in the DTD are the elements
#that are included.

my %elementsWithAttributes = ('MedlineCitation' => '1',
                           'OtherAbstract' => '1',
                           'KeywordList' => '1',
                           'Keyword' => '1',
                           'OtherID' => '1',
                           'GeneralNote' => '1',
                           'DataBankList' => '1',
                           'GrantList' => '1',
                           'AuthorList' => '1',
                           'DescriptorName' => '1',
                           'QualifierName' => '1');

#Create a hash of elements whose current array index needs to be
#tracked.

my %elementsTrackIndex = ('Chemical' => '1',
                       'CommentOn' => '1',
                       'CommentIn' => '1',
                       'ErratumIn' => '1',
                       'ErratumFor' => '1',
                       'RepublishedFrom' => '1',
                       'RepublishedIn' => '1',
                       'RetractionOf' => '1',
                       'RetractionIn' => '1',
                       'UpdateIn' => '1',
                       'UpdateOf' => '1',
                       'SummaryForPatientsIn' => '1',
                       'OriginalReportIn' => '1',
                       'DescriptorName' => '1',
                       'QualifierName' => '1',
                       'PersonalNameSubject' => '1',
                       'OtherAbstract' => '1',
                       'Keyword' => '1',
                       'OtherID' => '1',
                       'GeneralNote' => '1',
                       'Investigator' => '1',
                       'Author' => '1',
                       'Grant' => '1');
                       

# If there are no command-line arguments, ask for values to
# be entered as input. The number of the last subscript of the
# ARGV array ($#ARGV) is set to -1 initially. Thus, if there are
# no command-line arguments, $#ARGV will be < 0, whereas if
# there are command-line arguments, the $#ARGV will be > 0.
if($#ARGV <0){

   # Ask for the name of the input file.
   print "Please enter name of input file:";
   $main::inputFileName = <STDIN>;
   chomp($main::inputFileName);

   # Open the input file and associate a filehandle with it.
   open(main::INFILE, "<$main::inputFileName") || die ;

   #Ask for the name of the errorfile
   print "\n";
   print "Please enter name of error file:";
   $main::errorFileName = <STDIN>;
   chomp($main::errorFileName);

   #Open the error output file and associate a filehandle with it.
   open(main::ERRORFILE, ">$main::errorFileName");

   #Ask for the name of the log file
   print "\n";
   print "Please enter name of log file:";
   $main::logFileName = <STDIN>;
   chomp($main::logFileName);

   #Open the log output file and associate a filehandle with it.
   open(main::LOGFILE, ">>$main::logFileName");

   #Ask if the log should print the sizes of the output table files
   while(!((($main::printSizes) eq "sizes") || (($main::printSizes) eq "nosizes"))){
      print "Do you want the sizes of the table files to be printed
in the log?\n";
      print "Please enter \"sizes\", \"nosizes\", or \"exit\": \n";
      $main::printSizes = <STDIN>;
      chomp($main::printSizes);
      if($main::printSizes eq "exit"){
         exit;
     }
   } 

   #Ask if the data should be written directly to the database or
   #written to flat files.
   while(!((($main::dbOrFlatFile) eq "db") || (($main::dbOrFlatFile) eq "flatfile"))){
      print "Do you want to load data into the database or write to flat files?\n";
      print "Please enter \"db\" or \"flatfile\" or \"exit\": \n";
      $main::dbOrFlatFile = <STDIN>;
      chomp($main::dbOrFlatFile);
      if($main::dbOrFlatFile eq "exit"){
         exit;
     }
   } 

   if($main::dbOrFlatFile eq "db"){
      print "\n";
      print "Please enter username (or Control-C to quit):";
      $main::errorFileName = <STDIN>;
      chomp($main::username);

      print "\n";
      print "Please enter password (or Control-C to quit):";
      $main::errorFileName = <STDIN>;
      chomp($main::password);

   }

   if($main::dbOrFlatFile eq "flatfile"){
      #Ask if the set of output table files is new, or if a set of output
      #table files already exists
      while(!((($main::newOrAppend) eq "new") || (($main::newOrAppend) eq "append"))){
         print "Do you want to create new tables or does the set of tables already exist?\n";
         print "Please enter \"new\", \"append\", or \"exit\": \n";
         $main::newOrAppend = <STDIN>;
         chomp($main::newOrAppend);
         if($main::newOrAppend eq "exit"){
            exit;
        }
      }
   }

}

# If the number of arguments is greated than zero, then, store the values
# of the arguments in the appropriate variables

if($#ARGV > 0){
   # Collect values of arguments from command line.
   $main::inputFileName = $ARGV[0];
   $main::errorFileName = $ARGV[1];
   $main::logFileName = $ARGV[2];
   $main::printSizes = $ARGV[3];
   $main::dbOrFlatFile = $ARGV[4];
   $main::newOrAppend = $ARGV[5];
   $main::username = $ARGV[6];
   $main::password = $ARGV[7];

   # Set error flags to 0.
   $errorInFile = 0;
   $errorErrorFile = 0;
   $errorLogFile = 0;
   $errorPrintSizes = 0;
   $errorDBOrFlatFile = 0;
   $errorNewOrAppend = 0;  
  
   # Open the input file and associate a filehandle with it.
   open(main::INFILE, "<$main::inputFileName") or die print STDOUT "Could not open input file named $main::inputFileName: $!\n";
   # Check to see if input file is empty.
   if(eof(main::INFILE)){
      $main::errorInputFile = 1;
   }

   # Open the error output file and associate a filehandle with it.
   # If the file exists, but does not have write permission,
   # there will be an error.
   if($main::errorFileName eq ""){
      $main::errorErrorFile = 1;
   }
   else{
      open(main::ERRORFILE, ">$main::errorFileName") or die print STDOUT "Could not open error file named $main::errorFileName: $!\n";
   }
   
   # Open the log output file and associate a filehandle with it.
   # If the file does not exist, it will be created. It will
   # be opened for appending.
   if($main::logFileName eq ""){
      $main::errorLogFile = 1;
   }
   else{
      open(main::LOGFILE, ">>$main::logFileName") or die "Could not open log file named $main::logFileName: $!\n";
   }

   # Check value of $main::printSizes.
   # This flag indicates whether the user does or does not want to have
   # file sizes printed in the log file.
   if(!(($main::printSizes eq "sizes") ||
        ($main::printSizes eq "nosizes"))){
      $main::errorPrintSizes = 1;
   }
   
   # Check value of $main::dbOrFlatFile.
   if(!(($main::dbOrFlatFile eq "db") ||
        ($main::dbOrFlatFile eq "flatfile"))){
      $main::errordbOrFlatFiles = 1;
   }

   if($main::dbOrFlatFile eq "flatfile"){
   # Check value of $main::newOrAppend.
      if(!(($main::newOrAppend eq "new") ||
           ($main::newOrAppend eq "append"))){
         $main::errorNewOrAppend = 1;
      }
   }

   # If there are any errors, notify user, and exit.
   if($errorInFile ||
      $errorErrorFile ||
      $errorLogFile ||
      $errorPrintSizes ||
      $errorDBOrFlatFile ||
      $errorNewOrAppend){
      print STDOUT "Error in command-line arguments.\n";
      if($main::errorInFile){ 
         print STDOUT "The input file was empty.\n";
      }
      if($main::errorErrorFile){
         print STDOUT "No error file was entered.\n"; 
      }
      if($main::errorLogFile){
         print STDOUT "No log file was entered.\n"; 
      }
      if($main::errorPrintSizes){
         print STDOUT "The print-sizes variable must be \"sizes\" or \"nosizes\".\n";
      }      
      if($main::errorDBOrFlatFiles){
         print STDOUT "The tables must be opened as \"db\" or \"flatfile\".\n";
      }
      if($main::errorNewOrAppend){
         print STDOUT "The tables must be opened as \"new\" or \"append\".\n";
      }

      print STDOUT "Please enter arguments in the following order:\n";
      print STDOUT "(1) input file name\n";
      print STDOUT "(2) error file name\n";
      print STDOUT "(3) log file name\n";
      print STDOUT "(4) \"sizes\" or \"nosizes\"\n";
      print STDOUT "(5) \"db\" or \"flatfile\"\n";
      print STDOUT "(6) \"new\" or \"append\"\n";
      print STDOUT "\n";
      exit;
   }
}

if($main::dbOrFlatFile eq "db"){
   #Create the database handle. It should also be a file-level lexically
   #scoped variable. Other variables needed here are host, sid, port,
   #user, and pasword. These were set at the beginning of the file.
   #Make the connection to the database using the Oracle driver.

   $main::dbh = DBI->connect("dbi:Oracle:host=$main::host;sid=$main::sid;port=$main::port", 
                           $main::user, 
                           $main::password,
                           {PrintError => 1,
                            RaiseError => 1,
                            AutoCommit => 1})
                            or die "Can't connect to Oracle database: $DBI:errstr\n"; 

   my $sth = $main::dbh->prepare("
                    SELECT table_name
                    FROM user_tables");
                                        
   $sth->execute();
   
   while (my ($table_name) = $sth->fetchrow_array()){
      print "table_name = $table_name\n";
   }

   $sth->finish();
}

if(($main::dbOrFlatFile eq "flatfile") && ($main::newOrAppend eq "new")){

   #Open new table files for write access, and create the files
   #if they do not exist.
   openNewTables();
   
   #Write column headers in new table files
   #These column headers can be printed out to the text files for debugging,
   #but if they are, the first line of each table will have headers instead
   #of valid data.
#   writeColumnHeaders();

   #Close the file.
   closeTables();

   #Re-open the table files for read/write access.
   openExistingTables();
}
elsif($main::newOrAppend eq "append"){
   #Open existing table files for read/write access.
   openExistingTables();
}

#Initialize the start and end times.
$main::start = 0;
$main::end = 0;

# Initialize the parser
use XML::Parser::PerlSAX;

my $my_handler = MedlinePerlSAXHandler->new;
my $parser = XML::Parser::PerlSAX->new (Handler => $my_handler);

$main::start = time;

# Parse the input file
$parser->parse(Source=> {SystemId => $main::inputFileName});

$main::end = time;
#print STDOUT "time = ", scalar (localtime (time)), "\n";

closeTables();

open(main::LOGFILE, ">>$main::logFileName");

$main::startTimeStamp = scalar (localtime($main::start));
$main::endTimeStamp = scalar (localtime($main::end));

print main::LOGFILE "Input file: $main::inputFileName\n";
my @stats = stat($main::inputFileName);
my $size = $stats[7];
print main::LOGFILE " File size: $size bytes\n";
print main::LOGFILE "\n";
print main::LOGFILE "  Processing start time: $main::startTimeStamp\n";
print main::LOGFILE "  Processing end time: $main::endTimeStamp\n";
print main::LOGFILE "\n";

my $elapsedTimeSeconds = $main::end - $main::start;
my $hours = int ($elapsedTimeSeconds/3600);
my $remainingSeconds = $elapsedTimeSeconds % 3600;

my $minutes = int ($remainingSeconds/60);
$remainingSeconds = $remainingSeconds % 60;

my $seconds = $remainingSeconds;

print main::LOGFILE "Total processing time:\n";
print main::LOGFILE "   $hours hours\n";
print main::LOGFILE "   $minutes minutes\n";
print main::LOGFILE "   $seconds seconds\n";
print main::LOGFILE "\n";

if($main::dbOrFlatFile eq "flatfile"){
   my $totalSize = 0;
   my $file = "";

   if($main::printSizes eq "sizes"){
      print main::LOGFILE "Sizes of Flat-File Tables after Current Run\n";
      
      opendir(DIR, "$outputDirectoryPathForFlatFiles") || die "Can't open directory: $!\n";
      my @files = readdir(DIR);   
      print main::LOGFILE "---------------------------------------------------------------------\n";
      print main::LOGFILE "\n";
      print main::LOGFILE "DIRECTORY CONTAINING FLAT FILES: $outputDirectoryPathForFlatFiles\n";
      print main::LOGFILE "\n";
      printf main::LOGFILE "%-50s %-20s\n", "File Name", "File Size (bytes)";
      printf main::LOGFILE "%-50s %-20s\n", "------------------", "-----------------";
      foreach $file (@files){
        my $testsize = -s $file;
         if (!(-s $file)){
            open(FILEHANDLE, ("$outputDirectoryPathForFlatFiles"."/"."$file"));
            @stats = stat(FILEHANDLE);
            $size = $stats[7];
            $totalSize = $totalSize + $size;
            printf main::LOGFILE "%-50s %-20s\n", $file, $size;
            print main::LOGFILE "\n";
         }
      }
   }
   print main::LOGFILE "Total size of table files: $totalSize bytes\n";
   print main::LOGFILE "\n";

}


elsif($main::dbOrFlatFile eq "db"){
   my $totalNumRows = 0;

   if($main::printSizes eq "sizes"){

      print main::LOGFILE "Sizes of Database Tables after Current Run\n";
      print main::LOGFILE "\n";
      print main::LOGFILE "HOST: $host | USER: $user | PASSWORD: **********\n";
      print main::LOGFILE "\n";
      printf main::LOGFILE "%-50s %-20s\n", "Table Name", "Table Size (rows)";
      printf main::LOGFILE "%-50s %-20s\n", "-------------------", "-------------------";

      my @tables = $main::dbh->tables();    
      my $table_name = "";
    
      foreach my $table (@tables){
         #Get the name of the table
         if($table =~ /MEDLINEDEV.(.*)/){
	      $table_name = $1;
      
         #Create the (quoted) SQL statement. The use of $main::dbh->quote()
         #ensures the proper quoting required by database (e.g., by Oracle)
          $sql_statement = "SELECT * FROM $table_name";
          $quoted_sql_statement = $main::dbh->quote($sql_statement);

         #Prepare and execute the statement
         my $sth = $main::dbh->prepare("SELECT * FROM $table_name");
         $sth->execute();
      
         #Fetch the result of the query. The result is the number
         #of rows in this table.
         my $array_ref = $sth->fetchall_arrayref();
         my $row_count = scalar(@$array_ref);

         $totalNumRows = $totalNumRows + $row_count;
         printf main::LOGFILE "%-50s %-20s\n", $table_name, $row_count;
         print main::LOGFILE "\n";
         }
      }
   }

   print main::LOGFILE "Total number of rows in all tables: $totalNumRows\n";
   print main::LOGFILE "\n";

}

close main::INFILE;
close main::ERRORFILE;
close main::LOGFILE;

exit;

sub openNewTables{
   my $directoryName = $outputDirectoryPathForFlatFiles;

   #Open the output files and associate filehandles with them.
   #Use of "> $directoryName/file" opens a file for writing.
   #If the file does not exist, it will be created. Read access
   #is not permitted with ">".
   open(main::XML_FILE,
	"> $directoryName/XMLFile.dat");
   open(main::MEDLINE_CITATION,
 	"> $directoryName/MedlineCitation.dat");
   open(main::JOURNAL, 
	"> $directoryName/Journal.dat");
   open(main::MEDLINE_JOURNAL_INFO,
 	"> $directoryName/MedlineJournalInfo.dat");
   open(main::PMIDS_IN_FILE,
 	"> $directoryName/PMIDSInFile.dat");
   open(main::ABSTRACT,
 	"> $directoryName/Abstract.dat");
   open(main::CHEMICAL_LIST, 
	"> $directoryName/ChemicalList.dat");
   open(main::CITATION_SUBSETS, 
        "> $directoryName/CitationSubsets.dat");
   open(main::COMMENTS_CORRECTIONS,
 	"> $directoryName/CommentsCorrections.dat");
   open(main::GENE_SYMBOL_LIST,
 	"> $directoryName/GeneSymbolList.dat");
   open(main::MESH_HEADING_LIST, 
	"> $directoryName/MeshHeadingList.dat");
   open(main::QUALIFIER_NAMES, 
        "> $directoryName/QualifierNames.dat");
   open(main::PERSONAL_NAME_SUBJECT_LIST, 
        "> $directoryName/PersonalNameSubjectList.dat");
   open(main::OTHER_IDS,
 	"> $directoryName/OtherIDs.dat");
   open(main::KEYWORD_LIST, 
	"> $directoryName/KeywordList.dat");
   open(main::SPACE_FLIGHT_MISSIONS,
 	"> $directoryName/SpaceFlightMissions.dat");
   open(main::INVESTIGATOR_LIST, 
	"> $directoryName/InvestigatorList.dat");
   open(main::GENERAL_NOTES, 
	"> $directoryName/GeneralNotes.dat");
   open(main::AUTHOR_LIST,
 	"> $directoryName/AuthorList.dat");
   open(main::LANGUAGES, 
	"> $directoryName/Languages.dat");
   open(main::DATA_BANK_LIST, 
        "> $directoryName/DataBankList.dat");
   open(main::ACCESSION_NUMBER_LIST, 
        "> $directoryName/AccessionNumberList.dat");
   open(main::GRANT_LIST,
 	"> $directoryName/GrantList.dat");
   open(main::PUBLICATION_TYPE_LIST,
 	"> $directoryName/PublicationTypeList.dat");
}

sub closeTables{
   close main::XML_FILE;
   close main::MEDLINE_CITATION;
   close main::JOURNAL;
   close main::MEDLINE_JOURNAL_INFO;
   close main::PMIDS_IN_FILE;
   close main::ABSTRACT;
   close main::CHEMICAL_LIST; 
   close main::CITATION_SUBSETS; 
   close main::COMMENTS_CORRECTIONS;
   close main::GENE_SYMBOL_LIST;
   close main::MESH_HEADING_LIST; 
   close main::QUALIFIER_NAMES; 
   close main::PERSONAL_NAME_SUBJECT_LIST; 
   close main::OTHER_IDS;
   close main::KEYWORD_LIST; 
   close main::SPACE_FLIGHT_MISSIONS;
   close main::INVESTIGATOR_LIST; 
   close main::GENERAL_NOTES; 
   close main::AUTHOR_LIST;
   close main::LANGUAGES; 
   close main::DATA_BANK_LIST; 
   close main::ACCESSION_NUMBER_LIST; 
   close main::GRANT_LIST;
   close main::PUBLICATION_TYPE_LIST;
   close main::JOURNAL; 

}

sub openExistingTables{
#
# This subroutine opens existing table files. The files are 
# opened for read/write access.
   
   my $directoryName = $outputDirectoryPathForFlatFiles;

   #Open the output files and associate filehandles with them. The use
   #of "+< $directoryName/file" permits a file to be opened with
   #read/write access. It does not clobber data that exists in the
   #file, and it does not create a new file if the file does not exist.

   open(main::XML_FILE,
	"+< $directoryName/XMLFile.dat");
   open(main::MEDLINE_CITATION,
 	"+< $directoryName/MedlineCitation.dat");
   open(main::JOURNAL, 
	"+< $directoryName/Journal.dat");
   open(main::MEDLINE_JOURNAL_INFO,
 	"+< $directoryName/MedlineJournalInfo.dat");
   open(main::PMIDS_IN_FILE, 
	"+< $directoryName/PMIDSInFile.dat");
   open(main::ABSTRACT,
 	"+< $directoryName/Abstract.dat");
   open(main::CHEMICAL_LIST, 
	"+< $directoryName/ChemicalList.dat");
   open(main::CITATION_SUBSETS, 
        "+< $directoryName/CitationSubsets.dat");
   open(main::COMMENTS_CORRECTIONS,
 	"+< $directoryName/CommentsCorrections.dat");
   open(main::GENE_SYMBOL_LIST,
 	"+< $directoryName/GeneSymbolList.dat");
   open(main::MESH_HEADING_LIST, 
	"+< $directoryName/MeshHeadingList.dat");
   open(main::QUALIFIER_NAMES, 
        "+< $directoryName/QualifierNames.dat");
   open(main::PERSONAL_NAME_SUBJECT_LIST, 
        "+< $directoryName/PersonalNameSubjectList.dat");
   open(main::OTHER_IDS,
 	"+< $directoryName/OtherIDs.dat");
   open(main::KEYWORD_LIST, 
	"+< $directoryName/KeywordList.dat");
   open(main::SPACE_FLIGHT_MISSIONS,
 	"+< $directoryName/SpaceFlightMissions.dat");
   open(main::INVESTIGATOR_LIST,
 	"+< $directoryName/InvestigatorList.dat");
   open(main::GENERAL_NOTES,
 	"+< $directoryName/GeneralNotes.dat");
   open(main::AUTHOR_LIST,
 	"+< $directoryName/AuthorList.dat");
   open(main::LANGUAGES, 
	"+< $directoryName/Languages.dat");
   open(main::DATA_BANK_LIST, 
        "+< $directoryName/DataBankList.dat");
   open(main::ACCESSION_NUMBER_LIST, 
        "+< $directoryName/AccessionNumberList.dat");
   open(main::GRANT_LIST,
 	"+< $directoryName/GrantList.dat");
   open(main::PUBLICATION_TYPE_LIST,
 	"+< $directoryName/PublicationTypeList.dat");
}

sub writeColumnHeaders{

# This subroutine writes the column headers in each of the files opened
# in openNewTables(). If these are to be tables stored in Oracle,
# there is a 30-character limit on table names and column names.

   #Print column headers in each table
   print main::XML_FILE
      "xml_file_name", ",",
      "doc_type_name", ",",
      "dtd_public_id", ",",
      "dtd_system_id", ",",
      "time_processed", "\n"; 

   print main::MEDLINE_CITATION
      "pmid", ",",
      "medline_id", ",",
      "date_created", ",",
      "date_completed", ",",
      "date_revised", ",",
      "number_of_references", ",",
      "keyword_list_owner", ",",
      "citation_owner", ",",
      "citation_status", ",",
      "article_title", ",",
      "start_page", ",",
      "end_page", ",",
      "medline_pgn", ",",
      "article_affiliation", ",",
      "article_author_list_comp_yn", ",",
      "data_bank_list_complete_yn", ",",
      "grant_list_complete_yn", ",",
      "vernacular_title", ",",
      "date_of_electronic_publication", "\n"; 

   print main::JOURNAL 
      "pmid", ",",
      "issn", ",",
      "volume", ",",
      "issue", ",",
      "pub_date_year", ",",
      "pub_date_month", ",",
      "pub_date_day", ",",
      "pub_date_season", ",",
      "medline_date", ",",
      "coden", ",",
      "title", ",",
      "iso_abbreviation", "\n"; 

   print main::MEDLINE_JOURNAL_INFO
      "pmid", ",",
      "nlm_unique_id", ",",
      "medline_ta", ",",
      "country", "\n"; 

   print main::PMIDS_IN_FILE
      "xml_file_name", ",",
      "pmid", "\n"; 

   print main::ABSTRACT
      "pmid", ",",
      "abstract_text", ",",
      "copyright_information", "\n"; 

   print main::CHEMICAL_LIST
      "pmid", ",",
      "registry_number", ",",
      "name_of_substance", "\n"; 

   print main::CITATION_SUBSETS
      "pmid", ",",
      "citation_subset", "\n"; 

   print main::COMMENTS_CORRECTIONS
      "pmid", ",",
      "ref_source", ",",
      "ref_pmid_or_medlineid", ",",
      "ref_pmid", ",",
      "ref_medlineid", ",",
      "note", ",",
      "type", "\n"; 

   print main::GENE_SYMBOL_LIST
      "pmid", ",",
      "gene_symbol", "\n"; 

   print main::MESH_HEADING_LIST
      "pmid", ",",
      "descriptor_name", ",",
      "descriptor_name_major_yn", "\n"; 

   print main::QUALIFIER_NAMES
      "pmid", ",",
      "descriptor_name", ",",
      "qualifier_name", ",",
      "qualifier_name_major_yn","\n"; 

   print main::PERSONAL_NAME_SUBJECT_LIST
      "pmid", ",",
      "last_name", ",",
      "fore_name", ",",
      "first_name", ",",
      "middle_name", ",",
      "initials", ",",
      "suffix", "\n"; 

   print main::OTHER_IDS
      "pmid", ",",
      "other_id", ",",
      "other_id_source", "\n"; 

   print main::KEYWORD_LIST
      "pmid", ",",
      "keyword", ",",
      "keyword_major_yn", "\n"; 

   print main::SPACE_FLIGHT_MISSIONS
      "pmid", ",",
      "space_flight_mission", "\n"; 

   print main::INVESTIGATOR_LIST
      "pmid", ",",
      "last_name", ",",
      "fore_name", ",",
      "first_name", ",",
      "middle_name", ",",
      "initials", ",",
      "suffix", ",", 
      "investigator_affiliation", "\n"; 

   print main::GENERAL_NOTES
      "pmid", ",",
      "general_note", ",",
      "general_note_owner", "\n"; 

   print main::AUTHOR_LIST
      "pmid", ",",
      "personal_or_collective", ",",
      "last_name", ",",
      "fore_name", ",",
      "first_name", ",",
      "middle_name", ",",
      "initials", ",",
      "suffix", ",", 
      "collective_name", ",", 
      "author_affiliation", "\n"; 

   print main::LANGUAGES
      "pmid", ",",
      "language", "\n"; 

   print main::DATA_BANK_LIST 
      "pmid", ",",
      "data_bank_name", "\n"; 

   print main::ACCESSION_NUMBER_LIST 
      "pmid", ",",
      "data_bank_name", ",",
      "accession_number", "\n"; 

   print main::GRANT_LIST
      "pmid", ",",
      "grantid", ",",
      "acronym", ",",
      "agency", "\n"; 

   print main::PUBLICATION_TYPE_LIST 
      "pmid", ",",
      "publication_type", "\n"; 

}


## Initialize the handler package

## Document Handler Package

package MedlinePerlSAXHandler;

sub new{
   my $type = shift;
   return bless {}, $type;
}

sub clearMedlineCitationSetVariable{
   @MedlineCitationSet_MedlineCitation_PMID = ();
}

sub clearXMLElementVariables{
# This sub resets all variables that were created to collect data from
# an XML input file. They hold PCDATA described by the DTD.

   $MedlineCitation_MedlineID = "";
   $MedlineCitation_PMID = "";
   $MedlineCitation_DateCreated_Year = "";
   $MedlineCitation_DateCreated_Month = "";
   $MedlineCitation_DateCreated_Day = "";
   $MedlineCitation_DateCreated_Hour = "";
   $MedlineCitation_DateCreated_Minute= "";
   $MedlineCitation_DateCreated_Second = "";
   $MedlineCitation_DateCompleted_Year = "";
   $MedlineCitation_DateCompleted_Month = "";
   $MedlineCitation_DateCompleted_Day = "";
   $MedlineCitation_DateCompleted_Hour = "";
   $MedlineCitation_DateCompleted_Minute = "";
   $MedlineCitation_DateCompleted_Second = "";
   $MedlineCitation_DateRevised_Year = "";
   $MedlineCitation_DateRevised_Month = "";
   $MedlineCitation_DateRevised_Day = "";
   $MedlineCitation_DateRevised_Hour = "";
   $MedlineCitation_DateRevised_Minute = "";
   $MedlineCitation_DateRevised_Second = "";

   $MedlineCitation_KeywordList_Owner = "";
   $MedlineCitation_Owner = "";
   $MedlineCitation_Status = "";

   $MedlineCitation_MedlineJournalInfo_Country = "";
   $MedlineCitation_MedlineJournalInfo_MedlineTA = "";
   $MedlineCitation_MedlineJournalInfo_NlmUniqueID = "";

   @MedlineCitation_ChemicalList_Chemical_RegistryNumber = ();
   @MedlineCitation_ChemicalList_Chemical_NameOfSubstance = ();

   @MedlineCitation_CitationSubset = ();

   @MedlineCitation_CommentsCorrections_CommentOn_RefSource = ();
   @MedlineCitation_CommentsCorrections_CommentIn_RefSource = ();
   @MedlineCitation_CommentsCorrections_ErratumIn_RefSource = ();
   @MedlineCitation_CommentsCorrections_ErratumFor_RefSource = ();
   @MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource = ();
   @MedlineCitation_CommentsCorrections_RepublishedIn_RefSource = ();
   @MedlineCitation_CommentsCorrections_RetractionOf_RefSource = ();
   @MedlineCitation_CommentsCorrections_RetractionIn_RefSource = ();
   @MedlineCitation_CommentsCorrections_UpdateIn_RefSource = ();
   @MedlineCitation_CommentsCorrections_UpdateOf_RefSource = ();
   @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource = ();
   @MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource = ();

   @MedlineCitation_CommentsCorrections_CommentOn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_CommentIn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_ErratumIn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_ErratumFor_MedlineID = ();
   @MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID = ();
   @MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_RetractionOf_MedlineID = ();
   @MedlineCitation_CommentsCorrections_RetractionIn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_UpdateIn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_UpdateOf_MedlineID = ();
   @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID = ();
   @MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID = ();

   @MedlineCitation_CommentsCorrections_CommentOn_PMID = ();
   @MedlineCitation_CommentsCorrections_CommentIn_PMID = ();
   @MedlineCitation_CommentsCorrections_ErratumIn_PMID = ();
   @MedlineCitation_CommentsCorrections_ErratumFor_PMID = ();
   @MedlineCitation_CommentsCorrections_RepublishedFrom_PMID = ();
   @MedlineCitation_CommentsCorrections_RepublishedIn_PMID = ();
   @MedlineCitation_CommentsCorrections_RetractionOf_PMID = ();
   @MedlineCitation_CommentsCorrections_RetractionIn_PMID = ();
   @MedlineCitation_CommentsCorrections_UpdateIn_PMID = ();
   @MedlineCitation_CommentsCorrections_UpdateOf_PMID = ();
   @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID = ();
   @MedlineCitation_CommentsCorrections_OriginalReportIn_PMID = ();

   @MedlineCitation_CommentsCorrections_CommentOn_Note = ();
   @MedlineCitation_CommentsCorrections_CommentIn_Note = ();
   @MedlineCitation_CommentsCorrections_ErratumIn_Note = ();
   @MedlineCitation_CommentsCorrections_ErratumFor_Note = ();
   @MedlineCitation_CommentsCorrections_RepublishedFrom_Note = ();
   @MedlineCitation_CommentsCorrections_RepublishedIn_Note = ();
   @MedlineCitation_CommentsCorrections_RetractionOf_Note = ();
   @MedlineCitation_CommentsCorrections_RetractionIn_Note = ();
   @MedlineCitation_CommentsCorrections_UpdateIn_Note = ();
   @MedlineCitation_CommentsCorrections_UpdateOf_Note = ();
   @MedlineCitation_CommentsCorrections_SummaryForPatientsIn_Note = ();
   @MedlineCitation_CommentsCorrections_OriginalReportIn_Note = ();

   @MedlineCitation_GeneSymbolList_GeneSymbol = ();
   
   @MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName = ();

   @MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName_MajorTopicYN = ();

   @MedlineCitation_MeshHeadingList_MeshHeading_QualifierName = (); #2d array
   @MedlineCitation_MeshHeadingList_MeshHeading_QualifierName_MajorTopicYN = (); #2d array

   $MedlineCitation_NumberOfReferences = "";

   @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName = ();
   @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_ForeName = ();
   @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_FirstName = ();
   @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_MiddleName = ();
   @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Initials = ();
   @MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Suffix = ();

   @MedlineCitation_OtherID = ();
   @MedlineCitation_OtherID_Source = ();
   @MedlineCitation_OtherAbstract_AbstractText = ();
   @MedlineCitation_OtherAbstract_CopyrightInformation = ();
   @MedlineCitation_OtherAbstract_Type = ();
   @MedlineCitation_KeywordList_Keyword = ();
   @MedlineCitation_KeywordList_Keyword_MajorTopicYN = ();
   @MedlineCitation_SpaceFlightMission = ();

   @MedlineCitation_InvestigatorList_Investigator_LastName = ();
   @MedlineCitation_InvestigatorList_Investigator_ForeName = ();
   @MedlineCitation_InvestigatorList_Investigator_FirstName = ();
   @MedlineCitation_InvestigatorList_Investigator_MiddleName = ();
   @MedlineCitation_InvestigatorList_Investigator_Initials = ();
   @MedlineCitation_InvestigatorList_Investigator_Suffix = ();
   @MedlineCitation_InvestigatorList_Investigator_Affiliation = ();

   @MedlineCitation_GeneralNote = ();
   @MedlineCitation_GeneralNote_Owner = ();

   $Article_AuthorList_CompleteYN = "";
   $Article_DataBankList_CompleteYN = "";
   $Article_GrantList_CompleteYN = "";

   $Article_Journal = 0;

   $Article_ArticleTitle = "";
   $Article_Pagination_StartPage = "";
   $Article_Pagination_EndPage = "";
   $Article_Pagination_MedlinePgn = "";

   $Article_Abstract_AbstractText = "";
   $Article_Abstract_CopyrightInformation = "";

   $Article_Affiliation = "";

   @Article_AuthorList_Author_LastName = ();
   @Article_AuthorList_Author_ForeName = ();
   @Article_AuthorList_Author_FirstName = ();
   @Article_AuthorList_Author_MiddleName = ();
   @Article_AuthorList_Author_Initials = ();
   @Article_AuthorList_Author_Suffix = ();
   @Article_AuthorList_Author_CollectiveName = ();
   @Article_AuthorList_Author_Affiliation = ();

   @Article_Language = ();

   @Article_DataBankList_DataBank_DataBankName = ();
   @Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber = (); # 2d array

   @Article_GrantList_Grant_GrantID = ();
   @Article_GrantList_Grant_Acronym = ();
   @Article_GrantList_Grant_Agency = ();

   @Article_PublicationTypeList_PublicationType = ();
   $Article_VernacularTitle = "";
   $Article_DateOfElectronicPublication = "";

   $Article_Journal_ISSN = "";
   $Article_Journal_JournalIssue_Volume = "";
   $Article_Journal_JournalIssue_Issue = "";
   $Article_Journal_JournalIssue_PubDate_Year = "";
   $Article_Journal_JournalIssue_PubDate_Month = "";
   $Article_Journal_JournalIssue_PubDate_Day = "";
   $Article_Journal_JournalIssue_PubDate_Season = "";
   $Article_Journal_JournalIssue_PubDate_MedlineDate = "";
   $Article_Journal_Coden = "";
   $Article_Journal_Title = "";
   $Article_Journal_ISOAbbreviation = "";
 
}

sub clearIndexVariables{
   $chemical_i = -1;
   $commenton_i = -1;
   $commentin_i = -1;
   $erratumin_i = -1;
   $erratumfor_i = -1;
   $repubfrom_i = -1;
   $repubin_i = -1;
   $retractof_i = -1;
   $retractin_i = -1;
   $updatein_i = -1;
   $updateof_i = -1;
   $summaryin_i = -1;
   $origreport_i = -1;
   $descname_i = -1;
   $qualname_i = -1;
   $personalsub_i = -1;
   $otherab_i = -1;
   $investigator_i = -1;
   $articleauthor_i = -1;
   $grant_i = -1;
   $keyword_i = -1;
   $otherid_i = -1;
   $gennote_i = -1;
}

# So far, I have not used this
#
# Handle an xml_decl event
#
#sub xml_decl{
#   my($self, $properties) = @_;
#   my $version = $properties->{'Version'};
#   my $encoding = $properties->{'Encoding'};
#   my $standalone = $properties->{'Standalone'};
#   $main::xmlVersion = $version;
#}


#
# Handle a doctype_decl event
#
sub doctype_decl{
   my($self, $properties) = @_;
   my $name = $properties->{'Name'};
   my $pubid = $properties->{'PublicId'};
   my $systemid = $properties->{'SystemId'};
   $main::docTypeName = $name;
   $main::dtdPublicId = $pubid;
   $main::dtdSystemId = $systemid;
}

#
# Handle a start_document event
#
sub start_document{

   #Print starting information to error file.
#   print main::ERRORFILE "Begin processing file named $main::inputFileName\n";
   $main::startTime = time;
   $main::startTimeStamp = scalar (localtime($main::startTime));
#   print main::ERRORFILE "Time is $main::startTimeStamp\n";

}

#
# Handle an end_document event
#
sub end_document{

   #Print ending information to error file.
#   print main::ERRORFILE "End processing file named $main::inputFileName\n";
   $main::endTime = time;
   $main::endTimeStamp = scalar (localtime($main::endTime));
#   print main::ERRORFILE "Time is $main::endTimeStamp\n";

}

#
# Handle a start_element event
#
sub start_element{
   my($self, $properties) = @_;

   # Remember the name by pushing it onto the stack
   push(@elementStack, $properties->{'Name'});

   $elementName = $properties->{'Name'};
   $elementNumber++;

   # These lines can be uncommented for debugging, but generate
   # large quantities of data
 #  print main::ERRORFILE "<$elementName>   ($elementNumber)\n";
 #  print STDOUT "<$elementName>   ($elementNumber)\n";
   
   incrementIndexIfAppropriate();
   
   # Get attributes, if any, for this element
   if(exists $elementsWithAttributes{$elementName}){
      %attributes = %{$properties->{'Attributes'}};      
      setAttributes($elementName, \%attributes);
   }
}

sub incrementIndexIfAppropriate{

   $_ = $elementName;
   
   SWITCH: {
      if(exists $elementsTrackIndex{$elementName}){
   
         if(/^Chemical$/){
            $chemical_i++;
            $MedlineCitation_ChemicalList_Chemical_RegistryNumber[$chemical_i] = "";
            $MedlineCitation_ChemicalList_Chemical_NameOfSubstance[$chemical_i] = "";
            last SWITCH;
         }
   
         if(/^CommentOn$/){
            $commenton_i++;
            $MedlineCitation_CommentsCorrections_CommentOn_RefSource[$commenton_i] = "";
            $MedlineCitation_CommentsCorrections_CommentOn_PMID[$commenton_i] = "";
            $MedlineCitation_CommentsCorrections_CommentOn_MedlineID[$commenton_i] = "";
   $MedlineCitation_CommentsCorrections_CommentOn_Note[$commenton_i] = "";
            last SWITCH;
         }
   
         if(/^CommentIn$/){
            $commentin_i++;
            $MedlineCitation_CommentsCorrections_CommentIn_RefSource[$commentin_i] = "";
            $MedlineCitation_CommentsCorrections_CommentIn_PMID[$commentin_i] = "";
            $MedlineCitation_CommentsCorrections_CommentIn_MedlineID[$commentin_i] = "";
   $MedlineCitation_CommentsCorrections_CommentIn_Note[$commentin_i] = "";
            last SWITCH;
         }
   
         if(/^ErratumIn$/){
            $erratumin_i++;
            $MedlineCitation_CommentsCorrections_ErratumIn_RefSource[$erratumin_i] = "";
            $MedlineCitation_CommentsCorrections_ErratumIn_PMID[$erratumin_i] = "";
            $MedlineCitation_CommentsCorrections_ErratumIn_MedlineID[$erratumin_i] = "";
   $MedlineCitation_CommentsCorrections_ErratumIn_Note[$erratumin_i] = "";
            last SWITCH;
         }
   
         if(/^ErratumFor$/){
            $erratumfor_i++;
            $MedlineCitation_CommentsCorrections_ErratumFor_RefSource[$erratumfor_i] = "";
            $MedlineCitation_CommentsCorrections_ErratumFor_PMID[$erratumfor_i] = "";
            $MedlineCitation_CommentsCorrections_ErratumFor_MedlineID[$erratumfor_i] = "";
   $MedlineCitation_CommentsCorrections_ErratumFor_Note[$erratumfor_i] = "";
            last SWITCH;
         }
   
         if(/^RepublishedFrom$/){
            $repubfrom_i++;
            $MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource[$repubfrom_i] = "";
            $MedlineCitation_CommentsCorrections_RepublishedFrom_PMID[$repubfrom_i] = "";
            $MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID[$repubfrom_i] = "";
   $MedlineCitation_CommentsCorrections_RepublishedFrom_Note[$repubfrom_i] = "";
            last SWITCH;
         }
         if(/^RepublishedIn$/){
            $repubin_i++;
            $MedlineCitation_CommentsCorrections_RepublishedIn_RefSource[$repubin_i] = "";
            $MedlineCitation_CommentsCorrections_RepublishedIn_PMID[$repubin_i] = "";
            $MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID[$repubin_i] = "";
   $MedlineCitation_CommentsCorrections_RepublishedIn_Note[$repubin_i] = "";
            last SWITCH;
         }
         if(/^RetractionOf$/){
            $retractof_i++;
            $MedlineCitation_CommentsCorrections_RetractionOf_RefSource[$retractof_i] = "";
            $MedlineCitation_CommentsCorrections_RetractionOf_PMID[$retractof_i] = "";
            $MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$retractof_i] = "";
   $MedlineCitation_CommentsCorrections_RetractionOf_Note[$retractof_i] = "";
            last SWITCH;
         }
         if(/^RetractionIn$/){
            $retractin_i++;
            $MedlineCitation_CommentsCorrections_RetractionIn_RefSource[$retractin_i] = "";
            $MedlineCitation_CommentsCorrections_RetractionIn_PMID[$retractin_i] = "";
            $MedlineCitation_CommentsCorrections_RetractionIn_MedlineID[$retractin_i] = "";
   $MedlineCitation_CommentsCorrections_RetractionIn_Note[$retractin_i] = "";
            last SWITCH;
         }
         if(/^UpdateIn$/){
            $updatein_i++;
            $MedlineCitation_CommentsCorrections_UpdateIn_RefSource[$updatein_i] = "";
            $MedlineCitation_CommentsCorrections_UpdateIn_PMID[$updatein_i] = "";
            $MedlineCitation_CommentsCorrections_UpdateIn_MedlineID[$updatein_i] = "";
   $MedlineCitation_CommentsCorrections_UpdateIn_Note[$updatein_i] = "";
            last SWITCH;
         }
         if(/^UpdateOf$/){
            $updateof_i++;
            $MedlineCitation_CommentsCorrections_UpdateOf_RefSource[$updateof_i] = "";
            $MedlineCitation_CommentsCorrections_UpdateOf_PMID[$updateof_i] = "";
            $MedlineCitation_CommentsCorrections_UpdateOf_MedlineID[$updateof_i] = "";
   $MedlineCitation_CommentsCorrections_UpdateOf_Note[$updateof_i] = "";
            last SWITCH;
         }
         if(/^SummaryForPatientsIn$/){
            $summaryin_i++;
            $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource[$summaryin_i] = "";
            $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID[$summaryin_i] = "";
            $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID[$summaryin_i] = "";
   $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_Note[$summaryin_i] = "";
            last SWITCH;
         }
         if(/^OriginalReportIn$/){
            $origreport_i++;
            $MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource[$origreport_i] = "";
            $MedlineCitation_CommentsCorrections_OriginalReportIn_PMID[$origreport_i] = "";
            $MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID[$origreport_i] = "";
            $MedlineCitation_CommentsCorrections_OriginalReportIn_Note[$origreport_i] = "";
            last SWITCH;
         }
   
         if(/^DescriptorName$/){
            $descname_i++;
            $qualname_i = -1;
            $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName[$descname_i] = "";
            $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName_MajorTopicYN[$descname_i] = "";
            
            
            last SWITCH;
         }
   
         if(/^QualifierName$/){
            $qualname_i++;
            $MedlineCitation_MeshHeadingList_MeshHeading_QualifierName[$descname_i][$qualname_i] = "";
            $MedlineCitation_MeshHeadingList_MeshHeading_QualifierName_MajorTopicYN[$descname_i][$qualname_i] = "";
            last SWITCH;
         }
   
         if($elementName eq 'PersonalNameSubject'){
            $personalsub_i++;
   
   $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName[$personalsub_i] = "";
   $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_ForeName[$personalsub_i] = "";
   $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_FirstName[$personalsub_i] = "";
   $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_MiddleName[$personalsub_i] = "";
   $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Initials[$personalsub_i] = "";
   $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Suffix[$personalsub_i] = "";
            last SWITCH;
         }
   
         if(/^OtherAbstract$/){
            $otherab_i++;
            $MedlineCitation_OtherAbstract_AbstractText[$otherab_i] = "";
            $MedlineCitation_OtherAbstract_CopyrightInformation[$otherab_i] = "";
            $MedlineCitation_OtherAbstract_Type[$otherab_i] = "";
            last SWITCH;
         }
   
         if(/^Keyword$/){
            $keyword_i++;
            $MedlineCitation_KeywordList_Keyword[$keyword_i] = "";
    	    $MedlineCitation_KeywordList_Keyword_MajorTopicYN[$keyword_i]= "";      
    	 last SWITCH;
         }
   
         if(/^GeneralNote$/){
            $gennote_i++;
            $MedlineCitation_GeneralNote[$gennote_i] = "";
            $MedlineCitation_GeneralNote_Owner[$gennote_i] = "";
            last SWITCH;
         }
   
         if(/^OtherID$/){
            $otherid_i++;
            $MedlineCitation_OtherID[$otherid_i] = "";
            $MedlineCitation_OtherID_Source[$otherid_i] = "";
            last SWITCH;
         }
   
         if(/^Investigator$/){
            $investigator_i++;
   $MedlineCitation_InvestigatorList_Investigator_LastName[$investigator_i] = "";
   $MedlineCitation_InvestigatorList_Investigator_ForeName[$investigator_i] = "";
   $MedlineCitation_InvestigatorList_Investigator_FirstName[$investigator_i] = "";
   $MedlineCitation_InvestigatorList_Investigator_MiddleName[$investigator_i] = "";
   $MedlineCitation_InvestigatorList_Investigator_Initials[$investigator_i] = "";
   $MedlineCitation_InvestigatorList_Investigator_Suffix[$investigator_i] = "";
            last SWITCH;
         }
   
         if(/^Grant$/){
            $grant_i++;
            $Article_GrantList_Grant_GrantID[$grant_i] = "";
            $Article_GrantList_Grant_Agency[$grant_i] = "";
            $Article_GrantList_Grant_Acronym[$grant_i] = "";
            last SWITCH;
         }
   
         if(/^Author$/){
            $articleauthor_i++;
            $Article_AuthorList_Author_LastName[$articleauthor_i] = "";
            $Article_AuthorList_Author_ForeName[$articleauthor_i] = "";
            $Article_AuthorList_Author_FirstName[$articleauthor_i] = "";
            $Article_AuthorList_Author_MiddleName[$articleauthor_i] = "";
            $Article_AuthorList_Author_Initials[$articleauthor_i] = "";
            $Article_AuthorList_Author_Suffix[$articleauthor_i] = "";
            $Article_AuthorList_Author_CollectiveName[$articleauthor_i] = "";   
            last SWITCH;
         }   
      }
   }
}

sub setAttributes{
   my($elementName, $attributes) = @_;
  
   SWITCH: {

      if($elementName =~ /^MedlineCitation$/){
         $MedlineCitation_Owner = $attributes->{'Owner'};
         $MedlineCitation_Status = $attributes->{'Status'};
         last SWITCH;
      }

      if($elementName =~ /^OtherAbstract$/){
         $MedlineCitation_OtherAbstract_Type[$otherab_i] = $attributes->{'Type'};
         last SWITCH;
      }

      if($elementName =~ /^KeywordList$/){
         $MedlineCitation_KeywordList_Owner = $attributes->{'Owner'};
         last SWITCH;
      }

      if($elementName =~ /^Keyword$/){
         $MedlineCitation_KeywordList_Keyword_MajorTopicYN[$keyword_i] = $attributes->{'MajorTopicYN'};
         last SWITCH;
      }

      if($elementName =~ /^OtherID$/){
         $MedlineCitation_OtherID_Source[$otherid_i] = $attributes->{'Source'};
         last SWITCH;
      }
  
      if($elementName =~ /^GeneralNote$/){
         $MedlineCitation_GeneralNote_Owner[$gennote_i] = $attributes->{'Owner'};
         last SWITCH;
      }

      if($elementName =~ /^DataBankList$/){
         $Article_DataBankList_CompleteYN = $attributes->{'CompleteYN'};
         last SWITCH;
      }
      
      if($elementName =~ /^GrantList$/){
         $Article_GrantList_CompleteYN = $attributes->{'CompleteYN'};
         last SWITCH;
      }

      if($elementName =~ /^AuthorList$/){        
         $Article_AuthorList_CompleteYN = $attributes->{'CompleteYN'};
         last SWITCH;
      }
         
      if($elementName =~ /^DescriptorName$/){
        
         $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName_MajorTopicYN[$descname_i] = $attributes->{'MajorTopicYN'};
         last SWITCH;
      }

      if($elementName =~ /^QualifierName$/){
         $MedlineCitation_MeshHeadingList_MeshHeading_QualifierName_MajorTopicYN[$descname_i][$qualname_i] = $attributes->{'MajorTopicYN'};
         last SWITCH;
      }

      $nothing = 1;
   }
}

sub stackContains{
   my $guess = shift;
   foreach $element (@elementStack){
      return 1 if($element eq $guess);
   }
   return 0;
}

# 
# Handle an end_element event
#
sub end_element{
   my($self, $properties) = @_;

   $poppedElement = pop(@elementStack);  
   #Note that $properties->{'Name'} should = $poppedElement

#   print main::ERRORFILE "</$poppedElement>\n";
 
   SWITCH: {
      if($poppedElement eq "MedlineCitation"){
         #Print all the data that have been collected for this MedlineCitation.
         printMedlineCitationData();
         clearXMLElementVariables();
         clearIndexVariables();
         last SWITCH;
      }
      if($poppedElement eq "MedlineCitationSet"){
         printXMLFile();
         printPMIDsInFile();
         clearMedlineCitationSetVariable();
         last SWITCH;
      }
   }
}

#
# Handle a character data event
#
sub characters{
   my($self, $properties) = @_;

   $currentElement = $elementStack[$#elementStack];
   $text = $properties->{'Data'};   
   
   if(!($text eq "\n")){
#      print main::ERRORFILE "$text\n";
   }
   else{
#      print main::ERRORFILE "\n";      
   }

   if(stackContains("MedlineCitationSet")){
      doMedlineCitationSet();
   }
}

sub doMedlineCitationSet{
   $_ = $currentElement;
   if(stackContains("MedlineCitation")){
      doMedlineCitation();
   }
   elsif(stackContains("DeleteCitation")){
      doDeleteCitation();
   }
   else{
   }
}

sub doDeleteCitation{
   $_ = $currentElement;
   SWITCH: {
      if(/^PMID$/){
         push(@MedlineCitationSet_DeleteCitation_PMID, $text);
         last SWITCH;
      }
      if(/^MedlineID$/){
         push(@MedlineCitationSet_DeleteCitation_MedlineID, $text);
         last SWITCH;
      }
   }
}   

sub doMedlineCitation{   

   $_ = $currentElement;

   SWITCH: {
      #There are several places in the DTD where the element
      #"MedlineID" is used:
      #(1) MedlineCitation
      #(2) CommentsCorrections (%Ref.template)
      #(3) DeleteCitation
      #We must distinguish between these.
      if((/^MedlineID$/) 
             && (!(stackContains("CommentsCorrections")))
             && (!(stackContains("DeleteCitation")))){
         $MedlineCitation_MedlineID = $text;
         last SWITCH;
      }
      if((/^PMID$/) 
             && (!(stackContains("CommentsCorrections")))
             && (!(stackContains("DeleteCitation")))){
         $MedlineCitation_PMID = $text;
         push(@MedlineCitationSet_MedlineCitation_PMID, $text);
         last SWITCH;
      }
      if(stackContains("DateCreated")){
         doDateCreated(); 
         last SWITCH;
      }
      if(stackContains("DateCompleted")){
         doDateCompleted(); 
         last SWITCH;
      }
      if(stackContains("DateRevised")){
         doDateRevised(); 
         last SWITCH;
      }
      if(stackContains("Article")){
         doArticle(); 
         last SWITCH;
      }
      if(stackContains("MedlineJournalInfo")){
         doMedlineJournalInfo(); 
         last SWITCH;
      }
      if(stackContains("ChemicalList")){
         doChemicalList(); 
         last SWITCH;
      }
      if(/^CitationSubset$/){
         push(@MedlineCitation_CitationSubset, $text); 
         last SWITCH;
      }
      if(stackContains("CommentsCorrections")){
         doCommentsCorrections(); 
         last SWITCH;
      }
      if(stackContains("GeneSymbolList")){
         doGeneSymbolList(); 
         last SWITCH;
      }
      if(stackContains("MeshHeadingList")){
         doMeshHeadingList(); 
         last SWITCH;
      }
      if(/^NumberOfReferences$/){
         $MedlineCitation_NumberOfReferences = $text;
         last SWITCH;
      }
      if(stackContains("PersonalNameSubjectList")){
         doPersonalNameSubjectList(); 
         last SWITCH;
      }
      if(/^OtherID$/){
         $MedlineCitation_OtherID[$otherid_i] = $text; 
         last SWITCH;
      }
      if(stackContains("OtherAbstract")){
         doOtherAbstract(); 
         last SWITCH;
      }
      if(stackContains("KeywordList")){
         doKeywordList(); 
         last SWITCH;
      }
      if(/^SpaceFlightMission$/){
         push(@MedlineCitation_SpaceFlightMission, $text); 
         last SWITCH;
      }
      if(stackContains("InvestigatorList")){
         doInvestigatorList(); 
         last SWITCH;
      }
      if(/^GeneralNote$/){
         $MedlineCitation_GeneralNote[$gennote_i] = $text;
         last SWITCH;
      }
   }
}

sub doArticle{
   $_ = $currentElement;   
   SWITCH: {
      if(stackContains("Journal")){
         doJournal();
         last SWITCH;
      }
      if(/^ArticleTitle$/){
         $Article_ArticleTitle = $text;
         last SWITCH;
      }
      if(stackContains("Pagination")){
         doPagination();
         last SWITCH;
      }
      if(stackContains("Abstract")){
         doAbstract();
         last SWITCH;
      }
      if(/^Affiliation$/){
         $Article_Affiliation = $text;
         last SWITCH;
      }
      if(stackContains("AuthorList")){
         doArticleAuthorList();
         last SWITCH;
      }
      if(/^Language$/){
         push(@Article_Language, $text);
         last SWITCH;
      }
      if(stackContains("DataBankList")){
         doDataBankList();
         last SWITCH;
      }
      if(stackContains("GrantList")){
         doGrantList();
      }
      if(stackContains("PublicationTypeList")){
         doPublicationTypeList();
      }
      if(/^VernacularTitle$/){
         $Article_VernacularTitle = $text;
      }
      if(/^DateOfElectronicPublication$/){
         $Article_DateOfElectronicPublication = $text;
      }
      $nothing = 1;
   }
}

sub doDateCreated{
   $_ = $currentElement;
   SWITCH: {      
      if(/^Year$/){
         $MedlineCitation_DateCreated_Year = $text;
         last SWITCH;
      }
      if(/^Month$/){
         $MedlineCitation_DateCreated_Month = $text;
         last SWITCH;
      }
      if(/^Day$/){
         $MedlineCitation_DateCreated_Day = $text;
         last SWITCH;
      }
      if(/^Hour$/){
         $MedlineCitation_DateCreated_Hour = $text;
         last SWITCH;
      }
      if(/^Minute$/){
         $MedlineCitation_DateCreated_Minute = $text;
         last SWITCH;
      }
      if(/^Second$/){
         $MedlineCitation_DateCreated_Second = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doDateCompleted{
   $_ = $currentElement;
   SWITCH: {
      if(/^Year$/){
         $MedlineCitation_DateCompleted_Year = $text;
         last SWITCH;
      }
      if(/^Month$/){
         $MedlineCitation_DateCompleted_Month = $text;
         last SWITCH;
      }
      if(/^Day$/){
         $MedlineCitation_DateCompleted_Day = $text;
         last SWITCH;
      }
      if(/^Hour$/){
         $MedlineCitation_DateCompleted_Hour = $text;
         last SWITCH;
      }
      if(/^Minute$/){
         $MedlineCitation_DateCompleted_Minute = $text;
         last SWITCH;
      }
      if(/^Second$/){
         $MedlineCitation_DateCompleted_Second = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doDateRevised{
   $_ = $currentElement;
   SWITCH: {
      if(/^Year$/){
         $MedlineCitation_DateRevised_Year = $text;
         last SWITCH;
      }
      if(/^Month$/){
         $MedlineCitation_DateRevised_Month = $text;
         last SWITCH;
      }
      if(/^Day$/){
         $MedlineCitation_DateRevised_Day = $text;
         last SWITCH;
      }
      if(/^Hour$/){
         $MedlineCitation_DateRevised_Hour = $text;
         last SWITCH;
      }
      if(/^Minute$/){
         $MedlineCitation_DateRevised_Minute = $text;
         last SWITCH;
      }
      if(/^Second$/){
         $MedlineCitation_DateRevised_Second = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doMedlineJournalInfo{
   $_ = $currentElement;
   SWITCH: {
      if(/^Country$/){
         $MedlineCitation_MedlineJournalInfo_Country = $text;
         last SWITCH;
      }
      if(/^MedlineTA$/){
         $MedlineCitation_MedlineJournalInfo_MedlineTA = $text;
         last SWITCH;
      }
      if(/^NlmUniqueID$/){
         $MedlineCitation_MedlineJournalInfo_NlmUniqueID = $text;
         last SWITCH;
      }
   }
}
         
sub doChemicalList{
   $_ = $currentElement;
   if(stackContains("Chemical")){
      doChemical();
   }
}

sub doChemical{
   $_ = $currentElement;

   SWITCH: {
      if(/^RegistryNumber$/){
            $MedlineCitation_ChemicalList_Chemical_RegistryNumber[$chemical_i] = $text;
         last SWITCH;
      }
      if(/^NameOfSubstance$/){
            $MedlineCitation_ChemicalList_Chemical_NameOfSubstance[$chemical_i] = $text;
         last SWITCH;
      }
   }
}

sub doCommentsCorrections{
   $_ = $currentElement;
   SWITCH: {
      if(stackContains("CommentOn")){
         doCommentOn();
         last SWITCH;
     }
      if(stackContains("CommentIn")){
         doCommentIn();
         last SWITCH;
      }
      if(stackContains("ErratumIn")){
         doErratumIn();
         last SWITCH;
      }
      if(stackContains("ErratumFor")){
         doErratumFor();
         last SWITCH;
      }
      if(stackContains("RepublishedFrom")){
         doRepublishedFrom();
         last SWITCH;
      }  
      if(stackContains("RepublishedIn")){
         doRepublishedIn();
         last SWITCH;
      }  
      if(stackContains("RetractionOf")){
         doRetractionOf();
         last SWITCH;
      }
      if(stackContains("RetractionIn")){
         doRetractionIn();
         last SWITCH;
      }
      if(stackContains("UpdateIn")){
         doUpdateIn();
         last SWITCH;
      }
      if(stackContains("UpdateOf")){
         doUpdateOf();
         last SWITCH;
      }
      if(stackContains("SummaryForPatientsIn")){
         doSummaryForPatientsIn();
         last SWITCH;
      }
      if(stackContains("OriginalReportIn")){
         doOriginalReportIn();
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doCommentOn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_CommentOn_RefSource[$commenton_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_CommentOn_PMID[$commenton_i] = $text;
         last SWITCH;
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_CommentOn_MedlineID[$commenton_i] = $text;
         last SWITCH;
      }
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_CommentOn_Note[$commenton_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doCommentIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_CommentIn_RefSource[$commentin_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_CommentIn_PMID[$commentin_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_CommentIn_MedlineID[$commentin_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_CommentIn_Note[$commentin_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doErratumIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_ErratumIn_RefSource[$erratumin_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_ErratumIn_PMID[$erratumin_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_ErratumIn_MedlineID[$erratumin_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_ErratumIn_Note[$erratumin_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doErratumFor{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_ErratumFor_RefSource, $text[$erratumfor_i] = $text;

         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_ErratumFor_PMID[$erratumfor_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_ErratumFor_MedlineID, $text[$erratumfor_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_ErratumFor_Note[$erratumfor_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doRepublishedFrom{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource[$repubfrom_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_RepublishedFrom_PMID[$repubfrom_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID[$repubfrom_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_RepublishedFrom_Note[$repubfrom_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doRepublishedIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_RepublishedIn_RefSource[$repubin_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_RepublishedIn_PMID[$repubin_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID[$repubin_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_RepublishedIn_Note[$repubin_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doRetractionOf{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_RetractionOf_RefSource[$retractof_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_RetractionOf_PMID[$retractof_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$retractof_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_RetractionOf_Note[$retractof_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}
sub doRetractionIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_RetractionIn_RefSource[$retractin_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_RetractionIn_PMID[$retractin_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_RetractionIn_MedlineID[$retractin_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_RetractionIn_Note[$retractin_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doUpdateIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_UpdateIn_RefSource[$updatein_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_UpdateIn_PMID[$updatein_i] = $text;
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_UpdateIn_MedlineID[$updatein_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_UpdateIn_Note[$updatein_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doUpdateOf{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_UpdateOf_RefSource[$updateof_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_UpdateOf_PMID[$updateof_i] = $text;
         last SWITCH;
      }
     if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_UpdateOf_MedlineID[$updateof_i] = $text;
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_UpdateOf_Note[$updateof_i] = $text;
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doSummaryForPatientsIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource[$summaryin_i] = $text;
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID[$summaryin_i] = $text;         
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID[$summaryin_i] = $text;         
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_Note[$summaryin_i] = $text;         
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doOriginalReportIn{
   $_ = $currentElement;
   SWITCH: {
      if(/^RefSource$/){
         $MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource[$origreport_i] = $text;         
         last SWITCH;
      }
      if(/^PMID$/){
         $MedlineCitation_CommentsCorrections_OriginalReportIn_PMID[$origreport_i] = $text;         
         last SWITCH;
      }
      if(/^MedlineID$/){
         $MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID[$origreport_i] = $text;         
         last SWITCH;
      }
      if(/^Note$/){
         $MedlineCitation_CommentsCorrections_OriginalReportIn_Note[$origreport_i] = $text;         
         last SWITCH;
     }
     $nothing = 1;
   }
}

sub doGeneSymbolList{
   $_ = $currentElement;
   if(/^GeneSymbol$/){
      push(@MedlineCitation_GeneSymbolList_GeneSymbol, $text);
   }
}

sub doMeshHeadingList{
   $_ = $currentElement;
   if(stackContains("MeshHeading")){
      doMeshHeading();
   }
}

sub doMeshHeading{
   $_ = $currentElement;
   SWITCH: {
      if(/^DescriptorName$/){       
         $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName[$descname_i] = $text;
         last SWITCH;
      }
      if(/^QualifierName$/){ 
         $MedlineCitation_MeshHeadingList_MeshHeading_QualifierName[$descname_i][$qualname_i] =$text;
         last SWITCH;         
      }
      $nothing = 1;
   }
}

sub doPersonalNameSubjectList{
   $_ = $currentElement;
   if(stackContains("PersonalNameSubject")){
      SWITCH: {
         if(/^LastName$/){
            $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName[$personalsub_i] = $text;
            last SWITCH;
         }
         if(/^ForeName$/){
            $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_ForeName[$personalsub_i] = $text;
	    last SWITCH;
         }
         if(/^FirstName$/){
            $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_FirstName[$personalsub_i] = $text;
            last SWITCH;
         }
         if(/^MiddleName$/){
            $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_MiddleName[$personalsub_i] = $text;
	    last SWITCH;
         }
         if(/^Initials$/){
            $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Initials[$personalsub_i] = $text;
	    last SWITCH;
         }
         if(/^Suffix$/){
            $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Suffix[$personalsub_i] = $text;
	    last SWITCH;
         }
      }
   }
}

sub doOtherAbstract{
   $_ = $currentElement;
   if(/^AbstractText$/){
      $MedlineCitation_OtherAbstract_AbstractText[$otherab_i] = $MedlineCitation_OtherAbstract_AbstractText[$otherab_i].$text;
      last SWITCH;
   }
   if(/^CopyrightInformation$/){
$MedlineCitation_OtherAbstract_CopyrightInformation[$otherab_i] = $text;
      last SWITCH;
   }
   $nothing = 1;
}

sub doKeywordList{
   $_ = $currentElement;
   if(/^Keyword$/){
      $MedlineCitation_KeywordList_Keyword[$keyword_i] = $text;
      last SWITCH;
   }
}

sub doInvestigatorList{
   $_ = $currentElement;
   if(stackContains("Investigator")){
      SWITCH:{
         if(/^LastName$/){
            $MedlineCitation_InvestigatorList_Investigator_LastName[$investigator_i] = $text;
	    last SWITCH;
         }
         if(/^ForeName$/){
            $MedlineCitation_InvestigatorList_Investigator_ForeName[$investigator_i] = $text;
	    last SWITCH;
         }
         if(/^FirstName$/){
            $MedlineCitation_InvestigatorList_Investigator_FirstName[$investigator_i] = $text;
	    last SWITCH;
         }
         if(/^MiddleName$/){
            $MedlineCitation_InvestigatorList_Investigator_MiddleName[$investigator_i] = $text;
	    last SWITCH;
         }
         if(/^Initials$/){
            $MedlineCitation_InvestigatorList_Investigator_Initials[$investigator_i] = $text;
	    last SWITCH;
         }
         if(/^Suffix$/){
             $MedlineCitation_InvestigatorList_Investigator_Suffix[$investigator_i] = $text;
	     last SWITCH;
	 }
         if(/^Affiliation$/){
             $MedlineCitation_InvestigatorList_Investigator_Affiliation[$investigator_i] = $text;
             last SWITCH;
         }
      }
   }
}

sub doJournal{
   $_ = $currentElement;
   SWITCH: {
      if(/^ISSN$/){
         $Article_Journal_ISSN = $text;
         last SWITCH;
      }
      if(stackContains("JournalIssue")){
         doJournalIssue();
         last SWITCH;
      }
      if(/^Coden$/){
         $Article_Journal_Coden = $text;
         last SWITCH;
      }
      if(/^Title$/){
         $Article_Journal_Title = $text;
         last SWITCH;
      }
      if(/^ISOAbbreviation$/){
         $Article_Journal_ISOAbbreviation = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doJournalIssue{
   $_ = $currentElement;
   SWITCH:{
      if(/^Volume$/){
         $Article_Journal_JournalIssue_Volume = $text;
         last SWITCH;
      }
      if(/^Issue$/){
         $Article_Journal_JournalIssue_Issue = $text;
         last SWITCH;
      }
      if(stackContains("PubDate")){
         doJournalPubDate();
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doJournalPubDate{
  $_ = $currentElement;
   SWITCH:{
      if(/^Year$/){
         $Article_Journal_JournalIssue_PubDate_Year = $text;
        last SWITCH;
      }
      if(/^Month$/){
         $Article_Journal_JournalIssue_PubDate_Month = $text;
        last SWITCH;
      }
      if(/^Day$/){
         $Article_Journal_JournalIssue_PubDate_Day = $text;
         last SWITCH;
      }
      if(/^Season$/){
         $Article_Journal_JournalIssue_PubDate_Season = $text;
         last SWITCH;
      }
      if(/^MedlineDate$/){
         $Article_Journal_JournalIssue_PubDate_MedlineDate = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}
 
sub doPagination{
   $_ = $currentElement;
   
   
   SWITCH:{
      if(/^StartPage$/){
         $Article_Pagination_StartPage = $text;
         last SWITCH;
      }
      if(/^EndPage$/){
         $Article_Pagination_EndPage = $text;
         last SWITCH;
      }
      if(/^MedlinePgn$/){
         $Article_Pagination_MedlinePgn = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doAbstract{
   $_ = $currentElement;
   SWITCH:{
      if(/^AbstractText$/){
         #The previous value for the abstract text is prepended to the
         #current value. 
         #The is because it may contain one of the predefined XML entity
         #references such as < or & (which are represented as &#60; or &#38; 
         #respectively in the original XML file being read in). 
         #When the PerlSAX parser encounters such an entity reference, 
         #it goes back to subroutine characters without finishing grabbing the 
         #rest of the text within the element tags. It then reads in the
         #entity reference and goes back to subroutine characters again.
         #Finally, it reads in the remainder of the text, and completes
         #reading in the element.
         #Thus, if there is a < or & (which appear as &#60; or &#38; 
         #respectively in the original XML file being read in), $text will
         #first contain the text before the entity reference, second
         #contain the text of the entity reference, and third contain
         #the text after the entity reference. Therefore, we need to
         #append $text to what was previously collected.
         $Article_Abstract_AbstractText = $Article_Abstract_AbstractText.$text;
         last SWITCH;
      }
      if(/^CopyrightInformation$/){
         $Article_Abstract_CopyrightInformation = $text;
         last SWITCH;
      }
      $nothing = 1;
   }
}

sub doArticleAuthorList{
   $_ = $currentElement;
   SWITCH:{
      if(stackContains("Author")){
         if(/^LastName$/){
            $Article_AuthorList_Author_LastName[$articleauthor_i] = $text;
            last SWITCH;
         }
         if(/^ForeName$/){
            $Article_AuthorList_Author_ForeName[$articleauthor_i] = $text;
            last SWITCH;
         }
         if(/^FirstName$/){
            $Article_AuthorList_Author_FirstName[$articleauthor_i] = $text;
            last SWITCH;
         }
         if(/^MiddleName$/){
             $Article_AuthorList_Author_MiddleName[$articleauthor_i] = $text;
            last SWITCH;
        }
         if(/^Initials$/){
            $Article_AuthorList_Author_Initials[$articleauthor_i] = $text;
            last SWITCH;
         }
         if(/^Suffix$/){
            $Article_AuthorList_Author_Suffix[$articleauthor_i]  = $text;
            last SWITCH;
         }
         if(/^CollectiveName$/){
             $Article_AuthorList_Author_CollectiveName[$articleauthor_i]  = $text;
            last SWITCH;
        }
         if(/^Affiliation$/){
            $Article_AuthorList_Author_Affiliation[$articleauthor_i]  = $text;
            last SWITCH;
         }
      }
   }
}

sub doDataBankList{
   #Here we assume that if AccessionNumber is entered, DataBankName was just 
   #added. This is a reasonable assumption because the DTD requires DataBankName 
   #and makes AccessionNumberList optional for that DataBankName.
   $_ = $currentElement;
   if(stackContains("DataBank")){
      SWITCH:{
         if(/^DataBankName$/){
            push(@Article_DataBankList_DataBank_DataBankName, $text);
            last SWITCH;
         }
         if(stackContains("AccessionNumberList")){
            if(/^AccessionNumber$/){
               $lastIndex = $#Article_DataBankList_DataBank_DataBankName;
push(@{$Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber[$lastIndex]}, $text);
               last SWITCH;
            }
         }
      }
   }
}

sub doAccessionNumberList{
   $_ = $currentElement;
   SWITCH:
}   

sub doGrantList{
   $_ = $currentElement;
   if(stackContains("Grant")){
      SWITCH:{
         if(/^GrantID$/){
            $Article_GrantList_Grant_GrantID[$grant_i] = $text;
            last SWITCH;
         }
         if(/^Acronym$/){
            $Article_GrantList_Grant_Acronym[$grant_i] = $text;
            last SWITCH;
         }
         if(/^Agency$/){
            $Article_GrantList_Grant_Agency[$grant_i] = $text;
            last SWITCH;
         }
         $nothing = 1;
      }
   }
}

sub doPublicationTypeList{
   $_ = $currentElement;
   if(/^PublicationType$/){
      push(@Article_PublicationTypeList_PublicationType, $text);
   }
}

#
# Subroutines that write data to output tables
#
# The naming convention for these subroutines is to name the subroutine
# according to the name of the table in which a row is being inserted. If data 
# are being inserted into a number of tables then the subroutine is called 
# printXData, such as printMedlineCitationData, and printArticleData.
# If a print routine has the prefix "do" then this implies that the
# subroutine returns the id of the record that was just printed.

# The characters that enclose a field are two vertical bars. Be aware that
# there could be data fields in the XML data input file that have double  
# vertical bars.

sub printXMLFile{

    my $timeProcessed = scalar(localtime());

   if($main::dbOrFlatFile eq "flatfile"){
      seek(main::XML_FILE, 0, 2);

      print main::XML_FILE 
         "||", $main::inputFileName, "||,",
         "||", $main::docTypeName, "||,",
         "||", $main::dtdPublicId, "||,",
         "||", $main::dtdSystemId, "||,",
         "||", $timeProcessed, "||\n";  
   }
  
   if($main::dbOrFlatFile eq "db"){
      my $sth = $main::dbh->prepare("
                      INSERT INTO xml_file
                         (xml_file_name,
                          doc_type_name,
                          dtd_public_id,
                          dtd_system_id,
                          time_processed)
                       VALUES 
                         ('$main::inputFileName',
                          '$main::docTypeName',
                          '$main::dtdPublicId',
                          '$main::dtdSystemId',
                          '$timeProcessed')");
      $sth->execute();
      $sth->finish();
   }

}

sub printPMIDsInFile{

   if($main::dbOrFlatFile eq "flatfile"){
      seek(main::PMIDS_IN_FILE, 0, 2);

      for($i=0; $i<@MedlineCitationSet_MedlineCitation_PMID; $i++){
         print main::PMIDS_IN_FILE 
            "||", $main::inputFileName, "||,",
            "||", $MedlineCitationSet_MedlineCitation_PMID[$i], "||\n";  
      }
   }
  
   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitationSet_MedlineCitation_PMID; $i++){
         my $sth = $main::dbh->prepare("
                         INSERT INTO pmids_in_file
                            (xml_file_name,
                             pmid)
                         VALUES
                            ('$main::inputFileName',
                             '$MedlineCitationSet_MedlineCitation_PMID[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printMedlineCitationData{ 
# This subroutine prints all the data associated with a 
# MedlineCitation. Note that printMedlineCitation writes data only
# to one file: the MEDLINE_CITATION table.

   printMedlineCitation();
   printMedlineJournalInfo();
   printChemicalList();
   printCitationSubsets();
   printCommentsCorrections();
   printGeneSymbolList();
   printMeshHeadingList();
   printPersonalNameSubjectList();
   printAbstract();
   printOtherAbstracts();
   printOtherIDs();
   printKeywordList();
   printSpaceFlightMissions();
   printInvestigatorList();
   printGeneralNotes();
   printAuthorList();
   printLanguages();
   printDataBankList();
   printGrantList();
   printPublicationTypeList();
   printJournal();
}
   
sub printMedlineCitation{
# We record both a date and a timestamp. The reason for recording
# the data as a date is that it is easier to read. The reason for
# recording the data as a timestamp is so that we do not lose
# any information provided by the input XML file.

   my $dateCreated = "";
   my $timeCreated = "";
   my $dateCompleted = "";
   my $timeCompleted = "";
   my $dateRevised = "";
   my $timeRevised = "";

   $yearCreated = $MedlineCitation_DateCreated_Year;
   $monthCreated = $MedlineCitation_DateCreated_Month;
   $dayCreated = $MedlineCitation_DateCreated_Day;
   $hourCreated = $MedlineCitation_DateCreated_Hour;
   $minuteCreated = $MedlineCitation_DateCreated_Minute;
   $secondCreated = $MedlineCitation_DateCreated_Second;

   my $dateCreated = makeDate($yearCreated, $monthCreated, $dayCreated);
   my $timeCreated = makeTime($yearCreated, $monthCreated, $dayCreated, 
                           $hourCreated, $minuteCreated, $secondCreated);

   $yearCompleted = $MedlineCitation_DateCompleted_Year;
   $monthCompleted = $MedlineCitation_DateCompleted_Month;
   $dayCompleted = $MedlineCitation_DateCompleted_Day;
   $hourCompleted = $MedlineCitation_DateCompleted_Hour;
   $minuteCompleted = $MedlineCitation_DateCompleted_Minute;
   $secondCompleted = $MedlineCitation_DateCompleted_Second;

   my $dateCompleted = makeDate($yearCompleted, $monthCompleted, $dayCompleted);
   my $timeCompleted = makeTime($yearCompleted, $monthCompleted, $dayCompleted, 
                           $hourCompleted, $minuteCompleted, $secondCompleted);

   $yearRevised = $MedlineCitation_DateRevised_Year;
   $monthRevised = $MedlineCitation_DateRevised_Month;
   $dayRevised = $MedlineCitation_DateRevised_Day;
   $hourRevised = $MedlineCitation_DateRevised_Hour;
   $minuteRevised = $MedlineCitation_DateRevised_Minute;
   $secondRevised = $MedlineCitation_DateRevised_Second;

   my $dateRevised = makeDate($yearRevised, $monthRevised, $dayRevised);
   my $timeRevised = makeTime($yearRevised, $monthRevised, $dayRevised, 
                           $hourRevised, $minuteRevised, $secondRevised);

   if($main::dbOrFlatFile eq "flatfile"){
      seek(main::MEDLINE_CITATION, 0, 2);

      print main::MEDLINE_CITATION 
         "||", $MedlineCitation_PMID, "||,",
         "||", $MedlineCitation_MedlineID, "||,",
         "||", $dateCreated, "||,",
         "||", $dateCompleted, "||,",
         "||", $dateRevised, "||,",
         "||", $MedlineCitation_NumberOfReferences, "||,",
         "||", $MedlineCitation_KeywordList_Owner, "||,",
         "||", $MedlineCitation_Owner, "||,",
         "||", $MedlineCitation_Status, "||,",
         "||", $Article_ArticleTitle, "||,",
         "||", $Article_Pagination_StartPage, "||,",
         "||", $Article_Pagination_EndPage, "||,",
         "||", $Article_Pagination_MedlinePgn, "||,",
         "||", $Article_Affilitation, "||,",                             
         "||", $Article_AuthorList_CompleteYN, "||,",,
         "||", $Article_DataBankList_CompleteYN, "||,",
         "||", $Article_GrantList_CompleteYN, "||,",
         "||", $Article_VernacularTitle, "||,",             
         "||", $Article_DateOfElectronicPublication, "||\n"; 
   }
   
   if($main::dbOrFlatFile eq "db"){

      my $quoted_article_title = $main::dbh->quote($Article_ArticleTitle);
      my $quoted_article_affiliation = $main::dbh->quote($Article_Affiliation);
      my $quoted_vernacular_title = $main::dbh->quote($Article_VernacularTitle);

      my $sth = $main::dbh->prepare("
                   INSERT INTO medline_citation
        		(pmid,  
        		medlineid, 
        		date_created,
        		date_completed,
        		date_revised,
        		number_of_references,
        		keyword_list_owner,   
        		citation_owner,     
        		citation_status,   
        		article_title,
        		start_page,
        		end_page,
        		medline_pgn,
        		article_affiliation,
        		article_author_list_comp_yn,
        		data_bank_list_complete_yn,
        		grant_list_complete_yn,
        		vernacular_title,
        		date_of_electronic_publication)
                   VALUES
                      ('$MedlineCitation_PMID',
                       '$MedlineCitation_MedlineID',
                       '$dateCreated',
                       '$dateCompleted',
                       '$dateRevised',
                       '$MedlineCitation_NumberOfReferences',
                       '$MedlineCitation_KeywordList_Owner',
                       '$MedlineCitation_Owner',
                       '$MedlineCitation_Status',
                        $quoted_article_title,
                       '$Article_Pagination_StartPage',
                       '$Article_Pagination_EndPage',
                       '$Article_Pagination_MedlinePgn',
                        $quoted_article_affiliation,                             
                       '$Article_AuthorList_CompleteYN',
                       '$Article_DataBankList_CompleteYN',
                       '$Article_GrantList_CompleteYN',
                        $quoted_vernacular_title,             
                       '$Article_DateOfElectronicPublication')");
      $sth->execute();
      $sth->finish();
   
   }

}

sub makeDate{
  my ($year, $month, $day) = @_;  
  my $date = "";
  
  my %months = (1 => 'Jan',
                2 => 'Feb',
                3 => 'Mar',
                4 => 'Apr',
                5 => 'May',
                6 => 'Jun',
                7 => 'Jul',
                8 => 'Aug',
                9 => 'Sep',
                10 => 'Oct',
                11 => 'Nov',
                12 => 'Dec',
                '01' => 'Jan',
                '02' => 'Feb',
                '03' => 'Mar',
                '04' => 'Apr',
                '05' => 'May',
                '06' => 'Jun',
                '07' => 'Jul',
                '08' => 'Aug',
                '09' => 'Sep');
 my %days = (1 => '01',
             2 => '02',
             3 => '03',
             4 => '04',
             5 => '05',
             6 => '06',
             7 => '07',
             8 => '08',
             9 => '09',
             '01' => '01',
             '02' => '02',
             '03' => '03',
             '04' => '04',
             '05' => '05',
             '06' => '06',
             '07' => '07',
             '08' => '08',
             '09' => '09');

   my $monthIn3Letters = "";
   my $dayIn2Digits = 0;
   
   $monthIn3Letters = $months{$month};
   if($day < 10){
      $dayIn2Digits = $days{$day};
   }
   else{
      $dayIn2Digits = $day;
   }
   
   if((!($monthIn3Letters eq "")) &&
      (!($dayIn2Digits eq "")) &&
      (!($year eq ""))){
      $date = "$dayIn2Digits-$monthIn3Letters-$year"; 
      return $date;
   }
   
   if((!($monthIn3Letters eq "")) &&
      ($dayIn2Digits eq "") &&
      (!($year eq ""))){
      $date = "$monthIn3Letters-$year"; 
      return $date;
   }
   
   if(($monthIn3Letters eq "") &&
      ($dayIn2Digits eq "") &&
      (!($year eq ""))){
      $date = "$year"; 
      return $date;
   }
   
   return $date;
}

sub makeTime{
   my ($year, $month, $day, $hour, $minute, $second) = @_;
   my $time = "";
   #If all parameters are blank, set the $time string to blank.
   #Otherwise, set the $time string to the parameter values separated
   #by colons.
   if(($year eq "") && ($month eq "") && ($day eq "") && ($hour eq "") && ($minute eq "") && ($second eq "")){
      $time = "";
   }
   else{
      $time = "$year:$month:$day:$hour:$minute:$second";
   }
   return $time;
}

sub printMedlineJournalInfo{

   if($main::dbOrFlatFile eq "flatfile"){
      seek(main::MEDLINE_JOURNAL_INFO, 0, 2);

      print main::MEDLINE_JOURNAL_INFO
         "||", $MedlineCitation_PMID, "||,",
         "||", $MedlineCitation_MedlineJournalInfo_NlmUniqueID, "||,",
         "||", $MedlineCitation_MedlineJournalInfo_MedlineTA, "||,",
         "||", $MedlineCitation_MedlineJournalInfo_Country, "||\n";    
   }
   
   if($main::dbOrFlatFile eq "db"){
      my $sth = $main::dbh->prepare("
                   INSERT INTO medline_journal_info 
                      (pmid, 
                       nlm_unique_id,
                       medline_ta, 
                       country)
                   VALUES
                      ('$MedlineCitation_PMID',
                       '$MedlineCitation_MedlineJournalInfo_NlmUniqueID',
                       '$MedlineCitation_MedlineJournalInfo_MedlineTA',
                       '$MedlineCitation_MedlineJournalInfo_Country')");

      $sth->execute();
      $sth->finish();
   }  
   

}

sub printChemicalList{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::CHEMICAL_LIST, 0, 2);

      for($i=0; $i<@MedlineCitation_ChemicalList_Chemical_RegistryNumber; $i++){
         print main::CHEMICAL_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_ChemicalList_Chemical_RegistryNumber[$i], "||,",
            "||", $MedlineCitation_ChemicalList_Chemical_NameOfSubstance[$i], "||\n"; 
      }
   }
   
   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_ChemicalList_Chemical_RegistryNumber; $i++){

         my $quoted_registry_number = $main::dbh->quote($MedlineCitation_ChemicalList_Chemical_RegistryNumber[$i]);
         my $quoted_name_of_substance = $main::dbh->quote($MedlineCitation_ChemicalList_Chemical_NameOfSubstance[$i]);
 
         my $sth = $main::dbh->prepare("INSERT INTO chemical_list
                      VALUES
                          ('$MedlineCitation_PMID',
                            $quoted_registry_number,
                            $quoted_name_of_substance)");

         $sth->execute();
         $sth->finish();
      }
   }
   

}

sub printCitationSubsets{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::CITATION_SUBSETS, 0, 2);

      for($i=0; $i<@MedlineCitation_CitationSubset; $i++){
         print main::CITATION_SUBSETS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CitationSubset[$i], "||\n"; 
      }
   }
   
   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CitationSubset; $i++){
   
         my $sth = $main::dbh->prepare("
                      INSERT INTO citation_subsets
                         (pmid,
                          citation_subset)
                      VALUES
                         ('$MedlineCitation_PMID',
                          '$MedlineCitation_CitationSubset[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub getRefPMIDOrMedlineID{
   my ($pmid, $medlineid) = @_;
   my $ref_pmid_or_medlineid = "";
   if((!($pmid eq "")) && ($medlineid eq "")){
         $ref_pmid_or_medlineid = "P";
   }
   elsif(($pmid eq "") && (!($medlineid eq ""))){
         $ref_pmid_or_medlineid = "M";
   }
   return $ref_pmid_or_medlineid;
}


sub printCommentsCorrections{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::COMMENTS_CORRECTIONS, 0, 2);
   }

   # CommentOn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_CommentOn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                $MedlineCitation_CommentsCorrections_CommentOn_PMID[$i],
                $MedlineCitation_CommentsCorrections_CommentOn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_CommentOn_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,", "||",
$MedlineCitation_CommentsCorrections_CommentOn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_CommentOn_MedlineID[$i], "||,", "||",
$MedlineCitation_CommentsCorrections_CommentOn_Note[$i], "||,",
            "||", "CommentOn", "||\n"; 
      }

   }
   
   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_CommentOn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_CommentOn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_CommentOn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type) 
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_CommentOn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_CommentOn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_CommentOn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_CommentOn_Note[$i]', 
                         'CommentOn')");
         $sth->execute();
         $sth->finish();
      }

   }

   # CommentIn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_CommentIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_CommentIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_CommentIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_CommentIn_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,", "||",
$MedlineCitation_CommentsCorrections_CommentIn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_CommentIn_MedlineID[$i], "||,", "||",
$MedlineCitation_CommentsCorrections_CommentIn_Note[$i], "||,",
            "||", "CommentIn", "||\n"; 
      }        

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_CommentIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_CommentIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_CommentIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                       VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_CommentIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_CommentIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_CommentIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_CommentIn_Note[$i]', 
                         'CommentIn')");
         $sth->execute();
         $sth->finish();
      }

   }

   # ErratumIn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_ErratumIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_ErratumIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_ErratumIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_ErratumFor_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_ErratumFor_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_ErratumFor_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_ErratumFor_Note[$i], "||,",
            "||", "ErratumFor", "||\n"; 
      }        

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_ErratumIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_ErratumIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_ErratumIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_ErratumIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_ErratumIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_ErratumIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_ErratumIn_Note[$i]', 
                         'ErratumIn')");
         $sth->execute();
         $sth->finish();  
      }

   }

   # ErratumFor
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_ErratumFor_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_ErratumFor_PMID[$i],
                   $MedlineCitation_CommentsCorrections_ErratumFor_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_ErratumIn_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,", "||",
$MedlineCitation_CommentsCorrections_ErratumIn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_ErratumIn_MedlineID[$i], "||,", "||",
$MedlineCitation_CommentsCorrections_ErratumIn_Note[$i], "||,",
            "||", "ErratumIn", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_ErratumFor_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_ErratumFor_PMID[$i],
                   $MedlineCitation_CommentsCorrections_ErratumFor_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                        '$MedlineCitation_PMID',
                        '$MedlineCitation_CommentsCorrections_ErratumFor_RefSource[$i],'
                        '$ref_pmid_or_medlineid', 
                        '$MedlineCitation_CommentsCorrections_ErratumFor_PMID[$i]',
                        '$MedlineCitation_CommentsCorrections_ErratumFor_MedlineID[$i]',
                        '$MedlineCitation_CommentsCorrections_ErratumFor_Note[$i]', 
                         'ErratumFor')");
         $sth->execute();
         $sth->finish();   
      }

   }

   # RepublishedFrom

   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                $MedlineCitation_CommentsCorrections_RepublishedFrom_PMID[$i],
                $MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_RepublishedFrom_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RepublishedFrom_Note[$i], "||,",
            "||", "RepublishedFrom", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){

      for($i=0; $i<@MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_RepublishedFrom_PMID[$i],
                   $MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$currentCommentsCorrectionsID',
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_RepublishedFrom_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_RepublishedFrom_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_RepublishedFrom_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_RepublishedFrom_Note[$i]', 
                         'RepublishedFrom')");
         $sth->execute();
         $sth->finish();   
      }

   }

  # RepublishedIn

   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_RepublishedIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_RepublishedIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_Note[$i], "||,",
            "||", "RetractionOf", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){


      for($i=0; $i<@MedlineCitation_CommentsCorrections_RepublishedIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_RepublishedIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                          (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_RepublishedIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_RepublishedIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_RepublishedIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_RepublishedIn_Note[$i]', 
                         'RepublishedIn')");
         $sth->execute();
         $sth->finish(); 
      }

   }

   # RetractionOf
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_RetractionOf_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                $MedlineCitation_CommentsCorrections_RetractionOf_PMID[$i],
                $MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionOf_Note[$i], "||,",
            "||", "RetractionOf", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){

      for($i=0; $i<@MedlineCitation_CommentsCorrections_RetractionOf_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_RetractionOf_PMID[$i],
                   $MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_RetractionOf_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_RetractionOf_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_RetractionOf_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_RetractionOf_Note[$i]', 
                         'RetractionOf')");
         $sth->execute();
         $sth->finish(); 
      }

   }

   # RetractionIn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_RetractionOf_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_RetractionIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_RetractionIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionIn_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionIn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionIn_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_RetractionIn_Note[$i], "||,",
            "||", "RetractionIn", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){

      for($i=0; $i<@MedlineCitation_CommentsCorrections_RetractionIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_RetractionIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_RetractionIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_RetractionIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_RetractionIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_RetractionIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_RetractionIn_Note[$i]', 
                         'RetractionIn')");
         $sth->execute();
         $sth->finish();   
      }

   }

   # UpdateIn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_UpdateIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_UpdateIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_UpdateIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateIn_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateIn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateIn_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateIn_Note[$i], "||,",
            "||", "UpdateIn", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_UpdateIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_UpdateIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_UpdateIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_UpdateIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_UpdateIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_UpdateIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_UpdateIn_Note[$i]', 
                         'UpdateIn')");
         $sth->execute();
         $sth->finish();  
      }

   }

   # UpdateOf
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_UpdateOf_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_UpdateOf_PMID[$i],
                   $MedlineCitation_CommentsCorrections_UpdateOf_MedlineID[$i]);

          print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateOf_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateOf_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateOf_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_UpdateOf_Note[$i], "||,",
            "||", "UpdateOf", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_UpdateOf_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_UpdateOf_PMID[$i],
                   $MedlineCitation_CommentsCorrections_UpdateOf_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_UpdateOf_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_UpdateOf_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_UpdateOf_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_UpdateOf_Note[$i]', 
                         'UpdateOf')");
         $sth->execute();
         $sth->finish(); 
      }

   }
   
   # SummaryForPatientsIn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource[$i], "||,",
           "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID[$i], "||,", 
            "||",
            $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_Note[$i], "||,",
         "||", "SummaryForPatientsIn", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_SummaryForPatientsIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_SummaryForPatientsIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_SummaryForPatientsIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_SummaryForPatientsIn_Note[$i]', 
                         'SummaryForPatientsIn')");
         $sth->execute();
         $sth->finish(); 
      }

   }
   
   # OriginalReportIn
   if($main::dbOrFlatFile eq "flatfile"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                   $MedlineCitation_CommentsCorrections_OriginalReportIn_PMID[$i],
                   $MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID[$i]);

         print main::COMMENTS_CORRECTIONS
            "||", $currentCommentsCorrectionsID, "||,",
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource[$i], "||,",
            "||", $ref_pmid_or_medlineid, "||,",
            "||", $MedlineCitation_CommentsCorrections_OriginalReportIn_PMID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID[$i], "||,",
            "||", $MedlineCitation_CommentsCorrections_OriginalReportIn_Note[$i], "||,",
            "||", "OriginalReportIn", "||\n"; 
      }

   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource; $i++){
         my $ref_pmid_or_medlineid = getRefPMIDOrMedlineID(
                $MedlineCitation_CommentsCorrections_OriginalReportIn_PMID[$i],
                $MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID[$i]);
         my $sth = $main::dbh->prepare("
                      INSERT INTO comments_corrections
                         (pmid,
                          ref_source,
                          ref_pmid_or_medlineid,
                          ref_pmid,
                          ref_medlineid,
                          note,
                          type)         
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_CommentsCorrections_OriginalReportIn_RefSource[$i]',
                         '$ref_pmid_or_medlineid', 
                         '$MedlineCitation_CommentsCorrections_OriginalReportIn_PMID[$i]',
                         '$MedlineCitation_CommentsCorrections_OriginalReportIn_MedlineID[$i]',
                         '$MedlineCitation_CommentsCorrections_OriginalReportIn_Note[$i]', 
                         'OriginalReportIn')");
         $sth->execute();
         $sth->finish();   
      }

   }

}

sub printGeneSymbolList{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::GENE_SYMBOL_LIST, 0, 2);

      for($i=0; $i<@MedlineCitation_GeneSymbolList_GeneSymbol; $i++){ 
         print main::GENE_SYMBOL_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_GeneSymbolList_GeneSymbol[$i], "||\n"; 
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_GeneSymbolList_GeneSymbol; $i++){
   
         my $sth = $main::dbh->prepare("
                      INSERT INTO gene_symbol_list
                         (pmid,
                          gene_symbol)
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_GeneSymbolList_GeneSymbol[$i]')");
         $sth->execute();
         $sth->finish(); 
      }
   }
   

}

sub printMeshHeadingList{
   
   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::MESH_HEADING_LIST, 0, 2);
      
      for($i=0; $i<@MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName; $i++){
     
         print main::MESH_HEADING_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName[$i], "||,",
            "||", $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName_MajorTopicYN[$i], "||\n"; 
         printQualifierNames($i);
      }      
   }

   if($main::dbOrFlatFile eq "db"){

      for($i=0; $i<@MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName; $i++){

         my $quoted_descriptor_name = $main::dbh->quote($MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName[$i]);
         my $sth = $main::dbh->prepare("
                     INSERT INTO mesh_heading_list
                        (pmid,
                         descriptor_name,
                         descriptor_name_major_yn)
                     VALUES(
                        '$MedlineCitation_PMID',
                         $quoted_descriptor_name,
                        '$MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName_MajorTopicYN[$i]')");
         $sth->execute();
         $sth->finish();
         printQualifierNames($i);
      }                        
   }

}

sub printQualifierNames{
   my($i) = @_;

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::QUALIFIER_NAMES, 0, 2);
   
      for my $j (0..$#{$MedlineCitation_MeshHeadingList_MeshHeading_QualifierName[$i]}){
         print main::QUALIFIER_NAMES
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName[$i], "||,",
            "||", $MedlineCitation_MeshHeadingList_MeshHeading_QualifierName[$i][$j], "||,",
            "||", $MedlineCitation_MeshHeadingList_MeshHeading_QualifierName_MajorTopicYN[$i][$j], "||\n"; 
      }
   }
   
   if($main::dbOrFlatFile eq "db"){
      for my $j (0..$#{$MedlineCitation_MeshHeadingList_MeshHeading_QualifierName[$i]}){
         my $quoted_descriptor_name = $main::dbh->quote($MedlineCitation_MeshHeadingList_MeshHeading_DescriptorName[$i]);
         my $quoted_qualifier_name = $main::dbh->quote($MedlineCitation_MeshHeadingList_MeshHeading_QualifierName[$i][$j]);

         my $sth = $main::dbh->prepare("
                     INSERT INTO qualifier_names
                       (pmid,
                        descriptor_name,
                        qualifier_name,
                        qualifier_name_major_yn)
                     VALUES(
                        '$MedlineCitation_PMID',
                         $quoted_descriptor_name,
                         $quoted_qualifier_name,
                        '$MedlineCitation_MeshHeadingList_MeshHeading_QualifierName_MajorTopicYN[$i][$j]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printOtherIDs{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::OTHER_IDS, 0, 2);

      for($i=0; $i<@MedlineCitation_OtherID; $i++){
         print main::OTHER_IDS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_OtherID[$i], "||,",
            "||", $MedlineCitation_OtherID_Source[$i], "||\n"; 
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_OtherID; $i++){
         my $sth = $main::dbh->prepare("
                     INSERT INTO other_ids
                       (pmid,
                        other_id,
                        other_id_source)
                     VALUES(
                        '$MedlineCitation_PMID',
                        '$MedlineCitation_OtherID[$i]', 
                        '$MedlineCitation_OtherID_Source[$i]')");
         $sth->execute();
         $sth->finish();      
      }
   }

}

sub printAbstract{

   if($Article_Abstract_AbstractText eq ""){
      return;
   }

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::ABSTRACT, 0, 2);
 
      print main::ABSTRACT
         "||", $MedlineCitation_PMID, "||,",
         "||", $Article_Abstract_AbstractText, "||,",
         "||", $Article_Abstract_CopyrightInformation, "||,",
         "||", "AUTHOR", "||\n";
   }

   if($main::dbOrFlatFile eq "db"){
      my $quoted_abstract = $main::dbh->quote($Article_Abstract_AbstractText);
      my $quoted_AUTHOR = $main::dbh->quote("AUTHOR");

      my $sth = $main::dbh->do("
                INSERT INTO abstract
                   (pmid,
                    abstract_text,
                    copyright_information,
                    abstract_type)
                VALUES
                   ('$MedlineCitation_PMID',
                     $quoted_abstract,                       
                    '$Article_Abstract_CopyrightInformation',
                     $quoted_AUTHOR)");
   }

     
}

sub printOtherAbstracts{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::ABSTRACT, 0, 2);

      for($i=0; $i<@MedlineCitation_OtherAbstract_Type; $i++){
 
         print main::ABSTRACT
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_OtherAbstract_AbstractText[$i], "||,",
            "||", $MedlineCitation_OtherAbstract_CopyrightInformation[$i], "||,",
            "||", $MedlineCitation_OtherAbstract_Type[$i], "||\n";
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_OtherAbstract_Type; $i++){
         my $sth = $main::dbh->prepare("
                   INSERT INTO abstract
                      (pmid,
                       abstract_text,
                       copyright_information,
                       abstract_type)
                   VALUES
                      ('$MedlineCitation_PMID',
                       '$MedlineCitation_OtherAbstract_AbstractText[$i]',
                       '$MedlineCitation_OtherAbstract_CopyrightInformation[$i]',
                       '$MedlineCitation_OtherAbstract_Type[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }     

}

sub printKeywordList{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::KEYWORD_LIST, 0, 2);

      for($i=0; $i<@MedlineCitation_KeywordList_Keyword; $i++){
         print main::KEYWORD_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_KeywordList_Keyword[$i], "||,",
            "||", $MedlineCitation_KeywordList_Keyword_MajorTopicYN[$i], "||\n"; 
      }
   }

   if ($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_KeywordList_Keyword; $i++){
         my $sth = $main::dbh->prepare("
                      INSERT INTO keyword_list
                        (pmid,
                         keyword,
                         keyword_major_yn)
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$MedlineCitation_KeywordList_Keyword[$i]', 
                         '$MedlineCitation_KeywordList_Keyword_MajorTopicYN[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printSpaceFlightMissions{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::SPACE_FLIGHT_MISSIONS, 0, 2);

      for($i=0; $i<@MedlineCitation_SpaceFlightMission; $i++){
         print main::SPACE_FLIGHT_MISSIONS
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_SpaceFlightMission[$i], "||\n"; 
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_SpaceFlightMission; $i++){
         my $sth = $main::dbh->prepare("
                      INSERT INTO space_flight_missions
                         (pmid,
                          space_flight_mission)
                      VALUES(
                         '$MedlineCitation_PMID', 
                         '$MedlineCitation_SpaceFlightMission[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printGeneralNotes{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::GENERAL_NOTES, 0, 2);

      for($i=0; $i<@MedlineCitation_GeneralNote; $i++){
         print main::GENERAL_NOTES
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_GeneralNote[$i], "||,",
            "||", $MedlineCitation_GeneralNote_Owner[$i], "||\n"; 
         $currentGeneralNoteID++;
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_GeneralNote; $i++){
         my $sth = $main::dbh->prepare("
                      INSERT INTO general_notes
                         (pmid,
                          general_note,
                          general_note_owner)
                      VALUES(
                         '$MedlineCitation_PMID', 
                         '$MedlineCitation_GeneralNote[$i]',
                         '$MedlineCitation_GeneralNote_Owner[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printInvestigatorList{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::INVESTIGATOR_LIST, 0, 2);

      for($i=0; $i<@MedlineCitation_InvestigatorList_Investigator_LastName; $i++){

         print main::INVESTIGATOR_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_LastName[$i], "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_ForeName[$i], "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_FirstName[$i], "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_MiddleName[$i], "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_Initials[$i], "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_Suffix[$i], "||,",
            "||", $MedlineCitation_InvestigatorList_Investigator_Affiliation[$i], , "||\n"; 
      }
   }
   
   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_InvestigatorList_Investigator_LastName; $i++){

         my $lastName = $MedlineCitation_InvestigatorList_Investigator_LastName[$i];
         my $foreName = $MedlineCitation_InvestigatorList_Investigator_ForeName[$i];
         my $firstName = $MedlineCitation_InvestigatorList_Investigator_FirstName[$i];
         my $middleName = $MedlineCitation_InvestigatorList_Investigator_MiddleName[$i];
         my $initials = $MedlineCitation_InvestigatorList_Investigator_Initials[$i];
         my $suffix = $MedlineCitation_InvestigatorList_Investigator_Suffix[$i];
         my $investigator_affiliation = $MedlineCitation_InvestigatorList_Investigator_Affiliation[$i];

         my $quoted_lastName = $main::dbh->quote($lastName);
         my $quoted_foreName = $main::dbh->quote($foreName);
         my $quoted_firstName = $main::dbh->quote($firstName);
         my $quoted_middleName = $main::dbh->quote($middleName);
         my $quoted_initials = $main::dbh->quote($initials);
         my $quoted_suffix = $main::dbh->quote($suffix);
         my $quoted_investigator_affiliation = $main::dbh->quote($investigator_affiliation);

         my $sth = $main::dbh->prepare("
                   INSERT INTO investigator_list
                      (pmid,
                       last_name,
                       fore_name,
                       first_name,
                       middle_name,
                       initials,
                       suffix,
                       investigator_affiliation)
                   VALUES(
                       $MedlineCitation_PMID,
		       $quoted_lastName,
		       $quoted_foreName,
		       $quoted_firstName,
		       $quoted_middleName,
		       $quoted_initials,
		       $quoted_suffix,
                       $quoted_investigator_affiliation)");

         $sth->execute();
         $sth->finish();
      }
   }
   

     
}

sub printAuthorList{
   
   my $personalOrCollective = "";
      
   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::AUTHOR_LIST, 0, 2);

      for($i=0; $i<@Article_AuthorList_Author_LastName; $i++){

         #Determine if the author is a personal name or a collective name
         #and set the flag that indicates whether personal or collective
            
         if(!($Article_AuthorList_Author_LastName[$i] eq "")){
               $personalOrCollective = "P";
         }
         elsif(!($Article_AuthorList_Author_lectiveName[$i] eq "")){
            $personalOrCollective = "C";       
         }
 
         print main::AUTHOR_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $personalOrCollective, "||,",
            "||", $Article_AuthorList_Author_LastName[$i], "||,",
            "||", $Article_AuthorList_Author_ForeName[$i], "||,",
            "||", $Article_AuthorList_Author_FirstName[$i], "||,",
            "||", $Article_AuthorList_Author_MiddleName[$i], "||,",
            "||", $Article_AuthorList_Author_Initials[$i], "||,",
            "||", $Article_AuthorList_Author_Suffix[$i], "||,",
            "||", $Article_AuthorList_Author_CollectiveName[$i], "||,",
            "||", $Article_AuthorList_Author_Affiliation[$i], , "||\n"; 
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@Article_AuthorList_Author_LastName; $i++){
      
         #Determine if the author is a personal name or a collective name
         #and set the flag that indicates whether personal or collective
            
         if(!($Article_AuthorList_Author_LastName[$i] eq "")){
               $personalOrCollective = "P";
         }
         elsif(!($Article_AuthorList_Author_lectiveName[$i] eq "")){
            $personalOrCollective = "C";       
         }
            
         my $lastName = $Article_AuthorList_Author_LastName[$i];
         my $foreName = $Article_AuthorList_Author_ForeName[$i];
         my $firstName = $Article_AuthorList_Author_FirstName[$i];
         my $middleName = $Article_AuthorList_Author_MiddleName[$i];
         my $initials = $Article_AuthorList_Author_Initials[$i];
         my $suffix = $Article_AuthorList_Author_Suffix[$i];
         my $collectiveName = $Article_AuthorList_Author_CollectiveName[$i];
         my $authorAffiliation = $Article_AuthorList_Author_Affiliation[$i];

         my $quoted_lastName = $main::dbh->quote($lastName);
         my $quoted_foreName = $main::dbh->quote($foreName);
         my $quoted_firstName = $main::dbh->quote($firstName);
         my $quoted_middleName = $main::dbh->quote($middleName);
         my $quoted_initials = $main::dbh->quote($initials);
         my $quoted_suffix = $main::dbh->quote($suffix);
         my $quoted_collective_name = $main::dbh->quote($collective_name);
         my $quoted_author_affiliation = $main::dbh->quote($author_affiliation);
      
         my $sth = $main::dbh->prepare("
                   INSERT INTO author_list
                      (pmid,
                       personal_or_collective,
                       last_name,
                       fore_name,
                       first_name,
                       middle_name,
                       initials,
                       suffix,
                       collective_name,
                       author_affiliation)
                   VALUES(
                      '$MedlineCitation_PMID',
                      '$personal_or_collective',
		      $quoted_lastName,
		      $quoted_foreName,
		      $quoted_firstName,
		      $quoted_middleName,
		      $quoted_initials,
		      $quoted_suffix,
		      $quoted_collective_name,
                      $quoted_author_affiliation)");
         $sth->execute();
         $sth->finish();
      }
   }
   

  
}

sub printPersonalNameSubjectList{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::PERSONAL_NAME_SUBJECT_LIST, 0, 2);

      for($i=0; $i<@MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName; $i++){
         print main::PERSONAL_NAME_SUBJECT_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName[$i], "||,",          
            "||", $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_ForeName[$i], "||,",
            "||", $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_FirstName[$i], "||,",
            "||", $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_MiddleName[$i], "||,",
            "||", $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Initials[$i], "||,",
            "||", $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Suffix[$i], , "||\n"; 
      }
   }
   
   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName; $i++){
      
         my $lastName = $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_LastName[$i];
         my $foreName = $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_ForeName[$i];
         my $firstName = $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_FirstName[$i];
         my $middleName = $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_MiddleName[$i];
         my $initials = $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Initials[$i];
         my $suffix = $MedlineCitation_PersonalNameSubjectList_PersonalNameSubject_Suffix[$i];

         my $quoted_lastName = $main::dbh->quote($lastName);
         my $quoted_foreName = $main::dbh->quote($foreName);
         my $quoted_firstName = $main::dbh->quote($firstName);
         my $quoted_middleName = $main::dbh->quote($middleName);
         my $quoted_initials = $main::dbh->quote($initials);
         my $quoted_suffix = $main::dbh->quote($suffix);
   
         my $sth = $main::dbh->prepare("
                INSERT INTO personal_name_subject_list
                   (pmid,
                    last_name,
                    fore_name,
                    first_name,
                    middle_name,
                    initials,
                    suffix)
                VALUES(
                   $MedlineCitation_PMID,
		   $quoted_lastName,
		   $quoted_foreName,
		   $quoted_firstName,
		   $quoted_middleName,
		   $quoted_initials,
		   $quoted_suffix)");
		   
         $sth->execute();
         $sth->finish();
      }
   }
   

  
}

sub printLanguages{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::LANGUAGES, 0, 2);

      for($i=0; $i<@Article_Language; $i++){
         print main::LANGUAGES
            "||", $MedlineCitation_PMID, "||,",
            "||", $Article_Language[$i], "||\n"; 
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@Article_Language; $i++){
         my $sth = $main::dbh->prepare("
                      INSERT INTO languages
                         (pmid,
                          language)
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$Article_Language[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printDataBankList{
   
   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::DATA_BANK_LIST, 0, 2);

      for($i=0; $i<@Article_DataBankList_DataBank_DataBankName; $i++){
         $dataBankListID = $currentDataBankListID;
         print main::DATA_BANK_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $Article_DataBankList_DataBank_DataBankName[$i], "||\n"; 
         printAccessionNumberList($i);      
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@Article_DataBankList_DataBank_DataBankName; $i++){
         $dataBankListID = $currentDataBankListID;
         my $sth = $main::dbh->prepare("
                   INSERT INTO data_bank_list
                      (pmid,
                       data_bank_name)
                   VALUES(
                      '$MedlineCitation_PMID',
                      '$Article_DataBankList_DataBank_DataBankName[$i]')");
         $sth->execute();
         $sth->finish();
         printAccessionNumberList($i);      
      }
   }

}

sub printAccessionNumberList{
   my($i) = @_;

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::ACCESSION_NUMBER_LIST, 0, 2);

      for $j (0 .. $#{$Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber[$i]}){
         print main::ACCESSION_NUMBER_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $Article_DataBankList_DataBank_DataBankName[$i], "||,",
            "||", $Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber[$i][$j], "||\n"; 
      }   
   }
   
   if($main::dbOrFlatFile eq "db"){
      for $j (0 .. $#{$Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber[$i]}){
         my $sth = $main::dbh->prepare("
                   INSERT INTO accession_number_list
                      (pmid,
                       data_bank_name,
                       accession_number)
                   VALUES(
                      '$MedlineCitation_PMID',
                      '$Article_DataBankList_DataBank_DataBankName[$i]',
                      '$Article_DataBankList_DataBank_AccessionNumberList_AccessionNumber[$i][$j]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printGrantList{

   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::GRANT_LIST, 0, 2);

      for($i=0; $i<@Article_GrantList_Grant_GrantID; $i++){
      
         print main::GRANT_LIST
               "||", $MedlineCitation_PMID, "||,",
               "||", $Article_GrantList_Grant_GrantID[$i], "||,",
               "||", $Article_GrantList_Grant_Acronym[$i], "||,",
               "||", $Article_GrantList_Grant_Agency[$i], "||\n"; 
      }   
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@Article_GrantList_Grant_GrantID; $i++){

         my $sth = $main::dbh->prepare("
                   INSERT INTO grant_list
                      (pmid,
                       grantid,
                       acronym,
                       agency)
                   VALUES(
                      '$MedlineCitation_PMID',
                      '$Article_GrantList_Grant_GrantID[$i]',
		      '$Article_GrantList_Grant_Acronym[$i]',
		      '$Article_GrantList_Grant_Agency[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }
                   

}


sub printPublicationTypeList{
   
   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::PUBLICATION_TYPE_LIST, 0, 2);

      for($i=0; $i<@Article_PublicationTypeList_PublicationType; $i++){
         print main::PUBLICATION_TYPE_LIST
            "||", $MedlineCitation_PMID, "||,",
            "||", $Article_PublicationTypeList_PublicationType[$i], "||\n"; 
      }
   }

   if($main::dbOrFlatFile eq "db"){
      for($i=0; $i<@Article_PublicationTypeList_PublicationType; $i++){
         my $sth = $main::dbh->prepare("
                      INSERT INTO publication_type_list
                         (pmid,
                          publication_type)
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$Article_PublicationTypeList_PublicationType[$i]')");
         $sth->execute();
         $sth->finish();
      }
   }

}

sub printJournal{
   
   if($main::dbOrFlatFile eq "flatfile"){
      #Reset file position at end of file.
      seek(main::JOURNAL, 0, 2);

         print main::JOURNAL
            "||", $MedlineCitation_PMID, "||,",
            "||", $Article_Journal_ISSN, "||,",
            "||", $Article_Journal_JournalIssue_Volume, "||,",
            "||", $Article_Journal_JournalIssue_Issue, "||,",
            "||", $Article_Journal_JournalIssue_PubDate_Year, "||,",
            "||", $Article_Journal_JournalIssue_PubDate_Month, "||,",
            "||", $Article_Journal_JournalIssue_PubDate_Day, "||,",
            "||", $Article_Journal_JournalIssue_PubDate_Season, "||,",
            "||", $Article_Journal_JournalIssue_PubDate_Medline_Date, "||,",
            "||", $Article_Journal_Coden, "||,",
            "||", $Article_Journal_Title, "||,",
            "||", $Article_Journal_ISOAbbreviation, "||\n"; 
   }
   
   if($main::dbOrFlatFile eq "db"){
      my $sth = $main::dbh->prepare("
                      INSERT INTO journal
                         (pmid,
                          issn,
                          volume,
                          issue,
                          pub_date_year,
                          pub_date_month,
                          pub_date_day,
                          pub_date_season,
                          medline_date,
                          coden,
                          title,
                          iso_abbreviation)
                      VALUES(
                         '$MedlineCitation_PMID',
                         '$Article_Journal_ISSN',
                         '$Article_Journal_JournalIssue_Volume',
                         '$Article_Journal_JournalIssue_Issue',
                         '$Article_Journal_JournalIssue_PubDate_Year',
                         '$Article_Journal_JournalIssue_PubDate_Month',
                         '$Article_Journal_JournalIssue_PubDate_Day',
                         '$Article_Journal_JournalIssue_PubDate_Season',
                         '$Article_Journal_JournalIssue_PubDate_MedlineDate',
                         '$Article_Journal_Coden',
                         '$Article_Journal_Title',
                         '$Article_Journal_ISOAbbreviation')");
      $sth->execute();
      $sth->finish();
   }
   

   
}



