#!/usr/bin/env python
# -*- coding: utf-8 -*-

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
    if 'Label' in elem.attrib:
      abstr = elem.text
    
print abstr, "\n"


abstr_tokenized = nltk.word_tokenize(abstr)
abstr_tagged = filter_insignificant(nltk.pos_tag(abstr))

abstr_tokens = []

word_count = Counter()

for token in abstr_tagged:
  abstr_tokens.append(token[0])
  word_count[token[0]] += 1

print word_count

#outxml = "C:/path_to/xml_output_file.xml"
#with open(outxml, "w") as out:
    #valid_xmlstring = mystring.encode('latin1','xmlcharrefreplace').decode('utf8','xmlcharrefreplace')
    #out.write(valid_xmlstring) 
