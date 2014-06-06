#!/usr/bin/env python
# -*- coding: utf-8 -*-

import codecs

with codecs.open('pubmedtest.xml_bak', 'r', encoding="utf8") as file:
    list_of_all_the_records = file.read( ).split('\n\n')
file.close(  )
    
#file_object = open('testFileSplit.txt')
#list_of_all_the_records = file_object.read(  ).split('\n\n\n')
#file_object.close(  )

head = list_of_all_the_records.pop(0)
tail = '\n</PubmedArticleSet>'

#print head, tail

for record in list_of_all_the_records:
#  valid_xmlstring = record.encode('latin1','xmlcharrefreplace').decode('utf8','xmlcharrefreplace')
  xml = head + record + tail
 
  print ("Here's one", xml, "\nend\n\n\n")

#print "-".join(list_of_all_the_records)

#outxml = "C:/path_to/xml_output_file.xml"
#with open(outxml, "w") as out:
    #valid_xmlstring = mystring.encode('latin1','xmlcharrefreplace').decode('utf8','xmlcharrefreplace')
    #out.write(valid_xmlstring) 