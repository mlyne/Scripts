#!/usr/local/bin/perl -w

# supply path for additional perl modules
BEGIN{ push(@INC, "/home2/mlyne/SCRIPTS/AnT/AnT-0.02") }

# Specify modules
use strict;
use Getopt::Std;
use AnT::Searchfactory;
use AnT::Worker;
use AnT::Worker::BufferFH;
use AnT::Worker::Fasta::Search;
use AnT::Worker::Fasta::Result;
use AnT::Worker::Fasta::Hit;

my $file = shift;

my $search = AnT::Searchfactory->make(-file => "$file",
				      -program => 'fasta');

while (my $result = $search->next_result)
{
    printf("Result for db %s (%d sequences) db_size %d:\n",
            $result->database,
            $result->db_seqs,
            $result->db_size);

    foreach my $hit ($result->hits)
    {
        my $pc_cover = $hit->overlap / $hit->s_len;

        printf("Fasta hit to %s (%d aa); %2.0f%% id in %d overlap,
                E-value %s. Hit covers %2.0f%% of the subject,
                in frame %s\n",
                $hit->s_name,
                $hit->s_len,
                $hit->percent * 100, 
                $hit->overlap,
                $hit->expect,
                $pc_cover * 100,
	        $hit->frame);

	print "Opt:", $hit->opt, 
	      " Zscore:", $hit->zscore, 
	      " Swscore:", $hit->swscore,
	      " q_name:", $hit->q_name,
	      " q_len:", $hit->q_len,
	      " q_offset:", $hit->q_offset,
	"\n";

	print "q_begin:", $hit->q_begin,
	      " q_end:", $hit->q_end,
	      " s_name:", $hit->s_name,
#	      " s_type:", $hit->s_type,
	      " s_len:", $hit->s_len,
	      " s_begin:", $hit->s_begin,
	      " s_end:", $hit->s_end,
	      "\n\n";
    }
}

