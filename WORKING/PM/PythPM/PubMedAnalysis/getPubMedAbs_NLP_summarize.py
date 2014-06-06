#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import nltk
import numpy
import eUtils
import codecs
import argparse
from argparse import RawTextHelpFormatter

N = 100  # Number of words to consider
CLUSTER_THRESHOLD = 5  # Distance between words to consider
TOP_SENTENCES = 5  # Number of sentences to return for a "top n" summary

# Approach taken from "The Automatic Creation of Literature Abstracts" by H.P. Luhn
def _score_sentences(sentences, important_words):
    scores = []
    sentence_idx = -1

    for s in [nltk.tokenize.word_tokenize(s) for s in sentences]:

        sentence_idx += 1
        word_idx = []

        # For each word in the word list...
        for w in important_words:
            try:
                # Compute an index for where any important words occur in the sentence

                word_idx.append(s.index(w))
            except ValueError, e: # w not in this particular sentence
                pass

        word_idx.sort()

        # It is possible that some sentences may not contain any important words at all
        if len(word_idx)== 0: continue

        # Using the word index, compute clusters by using a max distance threshold
        # for any two consecutive words

        clusters = []
        cluster = [word_idx[0]]
        i = 1
        while i < len(word_idx):
            if word_idx[i] - word_idx[i - 1] < CLUSTER_THRESHOLD:
                cluster.append(word_idx[i])
            else:
                clusters.append(cluster[:])
                cluster = [word_idx[i]]
            i += 1
        clusters.append(cluster)

        # Score each cluster. The max score for any given cluster is the score 
        # for the sentence

        max_cluster_score = 0
        for c in clusters:
            significant_words_in_cluster = len(c)
            total_words_in_cluster = c[-1] - c[0] + 1
            score = 1.0 * significant_words_in_cluster \
                * significant_words_in_cluster / total_words_in_cluster

            if score > max_cluster_score:
                max_cluster_score = score

        scores.append((sentence_idx, score))

    return scores

def summarize(txt):
    sentences = [s for s in nltk.tokenize.sent_tokenize(txt)]
    normalized_sentences = [s.lower() for s in sentences]

    words = [w.lower() for sentence in normalized_sentences for w in
             nltk.tokenize.word_tokenize(sentence)]

    fdist = nltk.FreqDist(words)

    top_n_words = [w[0] for w in fdist.items() 
            if w[0] not in nltk.corpus.stopwords.words('english')][:N]

    scored_sentences = _score_sentences(normalized_sentences, top_n_words)

    top_n_scored = sorted(scored_sentences, key=lambda s: s[1])[-TOP_SENTENCES:]

    # Decorate the post object with summaries
    for idx,score in top_n_scored:
        sentences[idx] = '<b>' + sentences[idx] + '</b>'

    return sentences

if __name__ == '__main__':

    parser = argparse.ArgumentParser(
      prog = 'getPubMedAbs_NLP_summarize.py',
      description = """ Get the abstract from pubmed query and the important sentences being bolded""",
      formatter_class=RawTextHelpFormatter
    )
    parser.add_argument(
      '-q',
      '--query',
      metavar = 'q',
      type = str,
      nargs = '?',
      default = '.',
      help = 'pubmed query'
    )

    args = parser.parse_args()

    # Load in output from blogs_and_nlp__get_feed.py
    abst_data = eUtils.fetch_abstr(args.query)

    #f = open('output/results_summary.html', 'w')
    sys.stdout.write('<html><head><meta charset="utf-8"></head><body>\n')
    sys.stdout.write('<h1>There are %d abstracts available </h1>' % (len(abst_data)))
    for abs in abst_data:
        sys.stdout.write('<br/><h4><a href="http://www.ncbi.nlm.nih.gov/pubmed/%s">' % abs['pmid'])
        sys.stdout.write(abs['title'].encode('utf-8') + '</a></h4><br/>')
        summary = summarize(abs['text'])
        summary = [i.encode('utf-8') for i in summary]
        sys.stdout.write(' '.join(summary))
        sys.stdout.write('<br/>-----------<br/>')
    sys.stdout.write('\n</body></html>')
