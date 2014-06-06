#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import nltk
import numpy
import eUtils
from collections import defaultdict
import itertools
import operator
from math import log
import argparse
from argparse import RawTextHelpFormatter

def get_TermsFrequency(query_terms):
   """
   Count the frequency of MESH terms being used in all abstracts
   """
   abst_data = eUtils.fetch_abstr(query_terms)

   # node size: freq of term in all abstracts
   MESH_frequency = defaultdict(int)

   # edge weights: freq of bi-terms in all abstracts
   MESH_bifrequency = defaultdict(int)

   for abst in abst_data:
      MESH = abst['MESH']
      MESH_terms = sorted([i.strip(' ') for i in str(MESH).split(',')])
      # all bi-terms combinations
      MESH_biterms = itertools.combinations(MESH_terms, 2)
      for term in MESH_terms:
         MESH_frequency[term] += 1
      for biterm in MESH_biterms:
         MESH_bifrequency[biterm] += 1

   sorted_MESH_frequency = sorted(MESH_frequency.iteritems(), 
                                  key =operator.itemgetter(1), reverse=True)

   # filter the biterms at least occurs in 2 or more abstracts
   filter_MESH_bifrequency = dict((k,v) for k,v in MESH_bifrequency.iteritems()\
                                  if v > 1)
   sorted_MESH_bifrequency = sorted(filter_MESH_bifrequency.iteritems(), 
                                  key =operator.itemgetter(1), reverse=True)

   return (sorted_MESH_frequency, sorted_MESH_bifrequency)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(
        prog = 'getPubMedAbs_NLP_network.py',
        description = """Built the network of MESH associations.
        This program produces freq and bifreq.
        - Freq is used for node size parameter
        - biFreq is for the edge thickness""",
        formatter_class = RawTextHelpFormatter
  )
  parser.add_argument( 
         '-q', 
         '--query',
         metavar = 'q', 
         type = str,
         nargs = '?',
         default = '.',
         help = 'PubMed query'
  )
  parser.add_argument( 
         '-F_file',
         '--freq_file', 
         metavar = 'f', 
         type = str,
         nargs = '?',
         default = sys.stdout,
         help = 'file to stored the freq'
  )
  parser.add_argument( 
         '-biF_file',
         '--bifreq_file', 
         metavar = 'f', 
         type = str,
         nargs = '?',
         default = sys.stdout,
         help = 'file to stored the bifreq'
  )

  args = parser.parse_args()

  (MESH_freq, MESH_bifreq) = get_TermsFrequency(args.query)

  # print MESH_bifreq(for the network table, col3 for the edges weights)
  biFreq = open(args.freq_file, 'w')
  for (biterms, freq) in MESH_bifreq:
    biFreq.write(' '.join(terms.replace(' ', '_') for terms in biterms) + ' ' + \
                        str(log(freq)) + '\n')
  biFreq.close()

  # for the node table
  Freq = open(args.bifreq_file, 'w')
  for a,b in MESH_freq: Freq.write('%s %s\n' %(a.replace(' ','_'),b))
  Freq.close()

  # load these two files for cytoscape visualization!, enjoy!
