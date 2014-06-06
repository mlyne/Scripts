#!/usr/bin/env python
#__docformat__ = 'epytext en'

# General info
__version__ = '1.2.0'
__author__ = 'Carlos Rodriguez and Jaganadh G'
__url__ = 'http://www.cnio.es , http://jaganadhg.freeflux.net/blog'
__license__ = 'GNU GPL'

import time

import os
import re
import string
import urllib
from xml.dom.minidom import parseString

class BioReader(object):
    """
    Class BioReader for BioMedical files
    """
    def __init__(self, xml_string, path=None):
        """
        Initialize class with XML string  and returns record data and body of 
        text objects.
        """
        self.tags = re.compile("<.*?>")
        self.parsed = parseString(xml_string)
        self.document = self.parsed.documentElement
        self.pmid = self.document.getElementsByTagName("PMID")[0].firstChild.data
        self.year = self.document.getElementsByTagName("DateCreated")[0].\
        getElementsByTagName("Year")[0].firstChild.data
        self.journal = self.document.getElementsByTagName("MedlineJournalInfo")\
        [0].getElementsByTagName("MedlineTA")[0].firstChild.data
        self.testAbs = self.document.getElementsByTagName("Abstract")
        if path != None:
            self.path = path
            self.paper = self.getFullPaper()
        else:
            self.path = None
            self.paper = None
        try:
            self.year = self.document.getElementsByTagName("PubDate")[0].\
            getElementsByTagName("Year")[0].firstChild.data
        except IndexError:
            self.year = self.document.getElementsByTagName("DateCreated")[0].\
            getElementsByTagName("Year")[0].firstChild.data
        try:
            self.Abs = self.document.getElementsByTagName("Abstract")[0].\
            getElementsByTagName("AbstractText")[0].firstChild.data
        except IndexError:
            self.Abs = "n/a"
        self.title = self.document.getElementsByTagName("ArticleTitle")[0].\
        firstChild.data
        try:
            self.authorsList = self.document.getElementsByTagName("AuthorList")\
            [0].getElementsByTagName("Author")
            self.Lista = [self.authorize(y.childNodes) for y in self.authorsList]
            s = ""
            for x in self.Lista:
                s = s + x + "\n"
            self.auth = s
        except AttributeError:
            self.auth = " "
        except IndexError:
            self.auth = " "
        try:
            self.meshes = self.document.getElementsByTagName("MeshHeadingList")\
            [0].getElementsByTagName("MeshHeading")
            self.ListaMs = [self.meShes(z.childNodes) for z in self.meshes]
            self.MD = []
            self.MQ = []
            self.MDMay = []
            self.MQMay = []
            for z in self.meshes:
                MD, MQ, MDMay, MQMay = self.meshKeys(z)
                self.MD = MD + self.MD
                self.MQ = MQ + self.MQ
                self.MDMay = MDMay + self.MDMay
                self.MQMay = MQMay + self.MQMay

            self.m = ""
            for x in self.ListaMs:
                self.m = x + " \n " + self.m
            #self.p = None
        except IndexError:
            self.m = "n/a"
            self.meshes = "n/a"
            self.MQ = None
            self.MD = None
            self.MDMay = None
            self.MQMay = None
            #self.p = None
        #from DataContainer import repository
        #self.authors = string.join( self.Lista )#[self.authorize(x)+"\n"\]\
        #for x in self.Lista]

    def __repr__(self):
        return "<BioReader record instance: pmid: " + self.pmid + \
    " title: " + self.title + " abstract: " + self.Abs + ">"

    def authorize(self, node):
        s = ""
        for z in node:
            f = z.toxml()
            f = re.sub(self.tags, "", f)
            f = re.sub("\n", "", f)
            f = re.sub("\t", " ", f)
            f = re.sub("  ", "", f)
            s = s + f + " "
        return s

    def meShes(self, node):
        s = ""
        for z in node:
            f = z.toxml()
            f = re.sub(self.tags, "", f)
            f = re.sub("\n", "", f)
            f = re.sub("\t", " ", f)
            f = re.sub("  ", "", f)
            s = s + f + " "
        return s

    def meshKeys(self, node):
        """
        Create sets of MesH Keywords, separating qualifiers and descriptors,
        as well as //MajorTopics for each one. returns Lists.
        """
        listDescriptors = node.getElementsByTagName("DescriptorName")
        listQualifiers = node.getElementsByTagName("QualifierName")
        MD = [x.firstChild.data for x in listDescriptors]
        MQ = [x.firstChild.data for x in listQualifiers]
        MQMay = [q.firstChild.data for q in listQualifiers if (\
        q.getAttribute("MajorTopicYN") == "Y")]
        MDMay = [q.firstChild.data for q in listDescriptors if (\
        q.getAttribute("MajorTopicYN") == "Y")]
        return MD, MQ, MDMay, MQMay


    def getFullPaper(self):
        """
        Gets the full paper from the path of an (optional) repository.
        The full papers must have the following format:
        pmid+<pmidnumber>+.txt (last extension optional)
        """
        pmidList = os.listdir(self.path)
        if pmidList[0][-4:] == '.txt':
            pmidList = [x[4:-4] for x in pmidList]
            formato = 1
        else:
            pmidList = [x[4:] for x in pmidList]
            formato = None
        if self.pmid in pmidList:
            if formato:
                self.paper = open(self.path + "pmid" + self.pmid + ".txt")\
                .read()
                return self.paper
            else:
                self.paper = open(self.path + "pmid" + self.pmid).read()
                return self.paper
        else:
            self.paper = None


class DataContainer(object):
    """
    Data container for Pubmed and Medline XML files.
    The instance creates a dictionary object (dictRecords) of PMIDs, 
    referenced to string of record, which BioReader class can parse. 
    The method C{Read} creates a queryable object for each record 
     assoicated with a PMID:

        >>> from bioreader import *
        >>> data = DataContainer('AllAbs.xml','pubmed')
        >>> data.dictRecords.keys()[23]
        >>> u'7024555'
        >>> data.howmany
        >>> 14350

    1) Method One

       >>> record = data.read('7024555')
       >>> record.title

    u'The birA gene of Escherichia coli encodes a biotin 
    holoenzyme synthetase.'
    record +
                  - B{.title}
                  - B{.pmid}
                  - B{.Abs} I{(abstracts)}
                  - B{.year}
                  - B{.journal}
                  - B{.auth} I{(list of authors)}
                  - B{.m} I{(list of MeSH keywords, descriptors and 
                  qualifiers)}
                  - B{.MD} I{(MesH Descriptors)}
                  - B{.MQ} I{(MesH Qualifiers, if any)}
                  - B{.MDMay} I{(list of Mayor MesH Descriptors, if any)}
                  - B{.MQMay} I{(list of Mayor MesH Qualifiers, if any)}
                  - B{.paper} I{(full text flat file if exists in user-
                  defined repository [see notes below])}
    If we use a repository with full text papers 
    (with pmid+<pmidnumber>+txt format (extension optional), 
    we can use the following, after specifying it in the 
    DataContainer we instantiated:
        
    >>> data.repository("/repositorio/Regulontxt/")
    >>> record.paper

    'Aerobic Regulation of the sucABCD Genes of Escherichia coli,
     Which Encode \xef\xbf\xbd-Ketoglutarate Dehydrogenase andSuccinyl 
     Coenzyme A Synthetase: Roles of ArcA,Fnr, and the Upstream sdhCDAB
     Promoter\n.....

    2) Method two
        
    >>> record = data.dictRecords['7024555']
    >>> single_record = BioReader(record)
    >>> single_record.title
    >>> u'The birA gene of Escherichia coli encodes a biotin holoenzyme 
    synthetase.'   etc ...

    (See L{BioReader})
    """
    def __init__(self, file, format="medline"):
        """
        Initializes class and returns record data and body 
        of text objects
        """
        #import time
        tinicial = time.time()
        self.file = file
        whole = open(self.file).read()
        if format.lower() == "medline":
            self.rerecord = re.compile(r'\<MedlineCitation Owner="NLM" \
            Status="MEDLINE"\>'r'(?P<record>.+?)'r'\</MedlineCitation\>', \
            re.DOTALL)
        elif format.lower() == "pubmed":
            self.rerecord = re.compile(r'\<PubmedArticle\>'\
                                       r'(?P<record>.+?)'r'\</PubmedArticle\>',\
                                       re.DOTALL)
        else:
            print "Unrecognized format"
        self.RecordsList = re.findall(self.rerecord, whole)
        whole = ""
        self.RecordsList = ["<PubmedArticle>" + x.rstrip() + \
        "</PubmedArticle>" for x in self.RecordsList]
        self.dictRecords = self.createdict()
        self.RecordsList = []
        self.howmany = len(self.dictRecords.keys())
        self.keys = self.dictRecords.keys()
        tfinal = time.time()
        self.repo = None
        print "finished loading at ", time.ctime(tfinal)
        print "loaded in", tfinal - tinicial, " seconds, or", \
        ((tfinal - tinicial) / 60), " minutes"

        
    def __repr__(self):
        return "<BioReader Data Container Instance: source filename: " \
        + self.file + " \nnumber of files: " + str(self.howmany) + ">"
        

    def repository(self, repo):
        """
        Establish path to a full text repository, in case you want 
        to use that variable in the BioReader 
        """
        self.repo = repo
        return self.repo

    
    def createdict(self):
        """
        Creates a dictionary with pmid number indexing record xml string
        """
        i = 0
        dictRecords = {}
        for p in self.RecordsList:
            r = BioReader(p)
            dictRecords[r.pmid] = self.RecordsList[i]
            i += 1
        return dictRecords
    

    def read(self, pmid):
        if self.repo:
            self.record = BioReader(self.dictRecords[pmid], self.repo)
        else:
            self.record = BioReader(self.dictRecords[pmid])
        return self.record
    

    def search(self, search_string, where=None):
        """
        Searches for "search_string" string inside the selected field,
        and returns a list of pmid where it was found.

        If not "where" field is provided, will search in all of the record.
        You can search in the following fields:
         - title
         - year
         - journal
         - auth or authors
         - 'abs' or 'Abs' or 'abstract'
         - paper or "full" (if full-text repository has been defined)
         - pmid

        With defined field search is very slow but much more accurate. 
        See for comparison:
        
        >>> buscados = data.search("Richard")
        
        Searched in 0.110424995422  seconds, or 0.00184041659037  minutes

        Found a total of  75  hits for your query, in all fields

        >>> buscados = data.search("Richard","auth")

        Searched in 66.342936039  seconds, or 1.10571560065  minutes

        Found a total of  75  hits for your query, in the  auth  field
        """
        tinicial = time.time()
        resultlist = []
        
        if where:
            for cadapmid in self.dictRecords.keys():
                d = self.read(cadapmid)
                if where == 'title':
                    tosearch = d.title
                elif where == 'year':
                    tosearch = d.year
                elif where == 'journal':
                    tosearch = d.journal
                elif where == ('auth' or 'authors'):
                    tosearch = d.auth
                elif where == ('m' or 'mesh'):
                    tosearch = d.m
                elif where == ('abs' or 'Abs' or 'abstract'):
                    tosearch = d.Abs
                elif where == ('paper' or 'full'):
                    tosearch = d.paper
                    if self.repo:
                        pass
                    else:
                        print "No full text repository has been defined...."
                        return None
                elif where == 'pmid':
                    tosearch = d.pmid
                hit = re.search(search_string, tosearch)
                if hit:
                    resultlist.append(d.pmid)
                else:
                    pass

            tfinal = time.time()
            
            if len(resultlist) != 0:
                #tfinal = time.time()
                print "Searched in", tfinal - tinicial, " seconds, or", \
                ((tfinal - tinicial) / 60), " minutes"
                print "Found a total of ", str(len(resultlist)), \
                    " hits for your query, in the ", where, " field"
                return resultlist
            else:
                #tfinal = time.time()
                print "Searched in", tfinal - tinicial, " seconds, or", \
                ((tfinal - tinicial) / 60), " minutes"
                print "Query not found"
                return None
        else:
            tosearch = ''
            for cadapmid in self.dictRecords.keys():
                tosearch = self.dictRecords[cadapmid]
                hit = re.search(search_string, tosearch)
                if hit:
                    resultlist.append(cadapmid)
                else:
                    pass
        if len(resultlist) != 0:
            tfinal = time.time()
            print "Searched in", tfinal - tinicial, " seconds, or", \
                ((tfinal - tinicial) / 60), " minutes"
            print "Found a total of ", str(len(resultlist)), \
            " hits for your query, in all fields"
            return resultlist
        else:
            tfinal = time.time()
            print "Searched in", tfinal - tinicial, " seconds, or", \
                ((tfinal - tinicial) / 60), " minutes"
            print "Query not found"
            return None



class CreateXML(object):

    """
    From a set of PMID fteches abstract from ncbi.nlm.nih.gov 
    service. A PMID (PubMed Identifier or PubMed Unique Identifier) 
    is a unique number assigned to each PubMed citation of life sciences 
    and biomedical scientific journal articles.
    
    Usage:
       >>> from bioreader import CreateXML
       >>> outputfile = "NuevosPDFRegulon.xml"
       >>> inputfile = "/home/crodrigp/listaNuevos.txt"
       >>> XMLCreator = CreateXML()
       >>> XMLCreator.generateFile(outputfile,file=inputfile)
       >>> parseableString = XMLCreator.generate2String(file=inputfile)

       or
       >>> XMLString = XMLCreator.Generate2String(list=['19846864', \
       '19864182', '19846844'])
       
       The inputfile should contain one PMID per line. The output will be 
       stored to specified .xml file.
      
    
    """

    
    def __init__(self):
        """
        global urllib,time,string,random
        import urllib, time, string, random
        """
        self.BASEURL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id="
        self.OPTENDURL = "&retmode=xml"
                

    def __getXml(self, pmid):
        """
        Does the actual querying for the batches, and generates the XML
        """
        pedir = urllib.urlopen(self.BASEURL + pmid + self.OPTENDURL)
        stringxml = pedir.read()
        time.sleep(10)
        self.salida.write(stringxml + "\n")
        #self.salida.write(stringxml[:-20] + "\n")
        

    def __getXmlString(self, pmid):
        """
        Uses entrez tools to generate XML document. 
        """

        pedir = urllib.urlopen(self.BASEURL + pmid + self.OPTENDURL)
        stringxml = pedir.read()
        time.sleep(10)
        #return stringxml[:-20] + "\n"
        return stringxml + "\n"
    

    def __listastring(self, list):
        suso = string.join(list, ",")
        return suso
    


    def generateFile(self, outputfile, ** kwargs):
        """
        Queries pubmed and creates a XML file directly from responses.
         Will do batches of 100 since that is all Pubmed returns as XML
        """
        if len(kwargs.keys()) > 1: raise TypeError, "Invalid number of keyword arguments"

        LEGEL_ARGS = ["file", "list"]
        
        for key in kwargs.keys():
            if not key in LEGEL_ARGS:
                raise TypeError, "'%s' is an invalid keyword argument forthis function" \
                % key
        
        if kwargs.keys()[0] == "file": self.listaR = open(kwargs.values()[0], \
        'r').readlines()

        if kwargs.keys()[0] == "list" and kwargs['list'] == 'None':
            raise Exception,"There are no PMIDS"


        if kwargs.keys()[0] == "list": self.listaR = kwargs.values()[0]
        self.outputfile = outputfile
        #self.inputfile = inputfile
        self.salida = open(self.outputfile, "w")
        #self.listaR = open(self.inputfile).readlines()
        self.listafin = [x.rstrip() for x in self.listaR]
        self.listacorr = []
        while self.listafin != []:
            if len(self.listafin) < 100:
                cientos = self.listafin[:]
                #self.listafin = []
            else:
                cientos = self.listafin[:100]


            if len(self.listafin) <= 0:
                break
            else:
                time.sleep(10)
                nueva = self.__listastring(cientos)
                self.__getXml(nueva)
            for c in cientos:
                #print c # Jaggu
                self.listafin.remove(c)
        self.salida.close()
        

    def generate2String(self, ** kwargs):
        """
        Queries pubmed and returns a XML string from responses, 
        for further in-python processing (for example, with BioReader parser)
        """
        if len(kwargs.keys()) > 1: raise TypeError, "Invalid number of keyword arguments"
        LEGEL_ARGS = ["file", "list"]
        for key in kwargs.keys():
            if not key in LEGEL_ARGS:
                raise TypeError, "'%s' is an invalid keyword argument forthis function" % key
        if kwargs.keys()[0] == "file": self.listaR = open(kwargs.values()[0],\
        'r').readlines()
        if kwargs.keys()[0] == "list": self.listaR = kwargs.values()[0]
        #self.inputfile = inputfile
        #self.listaR = open(self.inputfile).readlines()
        self.AllXML = ''
        self.listafin = [x.rstrip() for x in self.listaR]
        self.listacorr = []
        while self.listafin != []:
            if len(self.listafin) < 100:
                cientos = self.listafin[:]
                #self.listafin = []
            else:
                cientos = self.listafin[:100]


            #print "new length self.listacorr", len(self.listafin)
            if len(self.listafin) <= 0:
                break
            else:
                time.sleep(10)
                nueva = self.__listastring(cientos)
                newX = self.__getXmlString(nueva)
                self.AllXML = self.AllXML + newX
            for c in cientos:
                #print c
                self.listafin.remove(c)
        return self.AllXML



class GetPmidsByTerm(object):
    """
    Class to keywords directly to pubmed. User can serch for pubmedids with a search
    string like 'blood cancer' etc... The function will check the correct spelling
    with the help of eutil espell utility and performs the search. It will
    return a list of pmids associated with the search term. The maximum number
    of pmids will be 100.
    
    Usage:
        >>> from bioreader import GetPmidsByTerm
        >>> obj = GetPmidsByTerm()
        >>> pmidlist = obj.querry("blood cancer")
        [u'20033885', u'20033841', u'20033382', u'20033259',.....
        ............]
        
    """

    def __init__(self):
        """
        Class initilization
        """
        self.BASEURL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="
        self.URLEND = "&reldate=60&datetype=edat&retmax=100&usehistory=y"

    def query(self, qterm):
        """
        Function to perform the qury and return the pmid list
        """
        trquery = self.__normalizeQuery(qterm)
        content = urllib.urlopen(self.BASEURL + trquery + self.URLEND).read()
        time.sleep(10)

        xmlcontent = parseString(content)

        try:
            idlist = [id.firstChild.data for id in \
            xmlcontent.getElementsByTagName('Id')]
        except:
            #idlist = None
            pass

        if len(idlist) != 0:
            return idlist
        else:
            #print "No result found for your search %s" % qterm
            return 'None'



    def __normalizeQuery(self, quer):
        """
        Private function to normalize query. Replaces space " " with "+".
        Also the function checks for spelling suggetion from pubmed using the
        http://eutils.ncbi.nlm.nih.gov/entrez/eutils/espell.fcgi?
        Service.
        ##db=pubmed&term=
        """
        quer = quer.replace(" ", "+")
        
        URL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/espell.fcgi?db=pubmed&term="
        sug = urllib.urlopen(URL + quer).read()
        time.sleep(10)
        sugxml = parseString(sug)

        try:
            suggetion = sugxml.getElementsByTagName('CorrectedQuery')[0].\
            firstChild.data
        except:
            suggetion = quer
            pass

        return suggetion.replace(" ", "+")



if __name__ == "__main__":
    br = GetPmidsByTerm()
    term = "lung cancer"
    l = br.query(term)
    XMLCreator = CreateXML()
    XMLString = XMLCreator.generate2String(list=l)
    print XMLString
