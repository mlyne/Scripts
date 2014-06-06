require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME     => 'AnT',
	      VERSION  => '0.02',
	      AUTHOR   => 'Keith James <kdj@sanger.ac.uk>',
	      dist     => {
			   TARFLAGS => 'cvf',
			   COMPRESS => 'gzip',
			   SUFFIX => 'gz'
			  },
	     );
