#!/usr/bin/env python

from lxml import etree
from StringIO import StringIO
from tokenize import generate_tokens
import nltk
from collections import Counter

def filter_insignificant(chunk, tag_suffixes=['DT', 'CC', ',', '.', ':', 'VBP', '!', 'CD']):
  good = []

  for word, tag in chunk:
    ok = True

    for suffix in tag_suffixes:
      if tag.endswith(suffix):
        ok = False
        break

    if ok:
      good.append((word, tag))

  return good



f = open("pubmedtest.xml")
xml_content = f.read()
f.close()

context = etree.iterparse(StringIO(xml_content))

for action, elem in context:
  if elem.tag == "ArticleTitle":
    title = elem.text
  elif elem.tag == "AbstractText":
    if elem.attrib["Label"] == "BACKGROUND":
      background = elem.text
    elif elem.attrib["Label"] == "METHODS":
      methods = elem.text
    elif elem.attrib["Label"] == "RESULTS":
      results = elem.text


background_tokenized = nltk.word_tokenize(background)
background_tagged = filter_insignificant(nltk.pos_tag(background_tokenized))

methods_tokenized = nltk.word_tokenize(methods)
methods_tagged = filter_insignificant(nltk.pos_tag(methods_tokenized))

results_tokenized = nltk.word_tokenize(results)
results_tagged = filter_insignificant(nltk.pos_tag(results_tokenized))

background_tokens = []
methods_tokens = []
results_tokens = []

word_count = Counter()

for token in background_tagged:
  background_tokens.append(token[0])
  word_count[token[0]] += 1

for token in methods_tagged:
  methods_tokens.append(token[0])
  word_count[token[0]] += 1

for token in results_tagged:
  results_tokens.append(token[0])
  word_count[token[0]] += 1

print word_count
