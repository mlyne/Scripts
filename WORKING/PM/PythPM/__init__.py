#!/usr/bin/env python
"""
Classes to download and process MedLine XML records. For example download abstracts
with PMID. A PMID (PubMed Identifier or PubMed Unique Identifier) is a unique
number assigned to each PubMed citation of life sciences and biomedical scientific
journal articles. The PMID has to be given as file. In the input file each line
should contain only one PMID. The abstracts can be stored in to an .xml file.
Further processigs can be done on the .xml file with the same module.

USAGE:
To get PMID by search keyword
	>>> from bioreader import GetPmidsByTerm
	>>> bio = GetPmidsByTerm()
	>>> keyword = "blood cancer"
	>>> res = bio.query(keyword)

	#It will return a list of PMIDs if the search is successful
        #To fetch abstacts with PMID

	>>> from bioreader import CreateXML
    >>> bioxml = CreateXML()
	>>> inputfile = "inp.txt" #input file contains each PMID in a single line
	>>> bioxml.generateFile("abs_n.xml",file=inputfile)
	>>> ## writes all the abstracts to abs_n.xml file
        #To load and querry in the fetched abstracts
    >>> from bioreader import DataContainer
	>>> data = DataContainer('abs_n.xml', 'pubmed')
	>>> data.howmany # prints number of abstracts
	>>> data.keys # prints the PMIDS
	>>> rec = data.read('19861069') # to read and store a particular abtsrct\
        #by PMID
            rec +
            B{.Abs}I{(returns the abstract)}
            B{.auth} I{(return the author details)}
            B{.pmid} I{( returns the PMID)}
            B{.title} I{(returns the title of the paper)}
            B{.year} I{(returns the published year)}
            B{.journal} I{(returns the name of Journal in which the paper appeared)}
            B{.m} I{(returns the Mesh keywords)}
            B{.MD} I{( returns MESH description)}
            B{.MQ} I{ (returns MesH Qualifiers)}
            B{.MDMay} I{(list of Mayor MesH Descriptors, if any)}
            B{.MQMay} I{(list of Mayor MesH Qualifiers, if any)}
            B{.paper}  I{(full text flat file if exists in user-
                  #defined repository [see notes below])}
        
	>>> data.search("influenza", where='title')  # search for a particular
        #keyword occouring in
        #TODO Not working have to fix it
	    ## title
    >>> data.repository('/home/developer/Desktop/abs/') #Setting a repostory of full
        #papers/abstract. The file name should be pmid + .txt
        #TODO Not working have to fix it

"""
from bioreader import *
__all__ = [
'CreateXML', 'BioReader', 'DataContainer', 'GetPmidsByTerm'
]
