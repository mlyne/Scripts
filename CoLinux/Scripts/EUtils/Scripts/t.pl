#!/usr/bin/perl
use LWP::Simple;

$base="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";

while(<>){
chomp;
$term=$_."[gene]";

$url=$base."esearch.fcgi?db=homologene&term=$term";
$result= get($url);
if($result!~/<Id>(\d+)<\/Id>/){next;}
$id=$1;

$url=$base."elink.fcgi?db=nucleotide&dbfrom=homologene&id=$id";
$result=get($url);
#print $result;

if($result!~/(<LinkSetDb.+<\/LinkSetDb>)/s){next;};$r=$1;
#print $r;
while($r=~/<Id>(\d+)<\/Id>/g){push @ids,$1;}

foreach $id (@ids){#each transcript
$url=$base."elink.fcgi?db=gene&dbfrom=nucleotide&id=$id";
$result=get($url);
#print $result;

if($result!~/(<LinkSetDb.+<\/LinkSetDb>)/s){next;};$r=$1;
$r=~/<Id>(\d+)<\/Id>/;$id=$1;

$url=$base."efetch.fcgi?db=gene&id=$id&retmode=xml";
$result=get($url);

if($result!~/(<Gene-commentary_type value="genomic".+?<\/Gene-commentary_seqs>)/s){next;};
$r=$1;

$r=~/<Seq-interval_from>(\d+)/;$from=$1;
$r=~/<Seq-interval_to>(\d+)/;$to=$1;
$r=~/<Na-strand value="(.+?)"\/>/;$strand=$1;
$r=~/<Seq-id_gi>(\d+)/;$uid=$1;

if($strand eq "plus"){$s=1;$to=$from;$from-=1000;}else{$s=2;$from=$to;$to+=1000;}


#print "from: $from\nTo: $to\nStrand: $strand\nUID: $uid\n";

$url=$base."efetch.fcgi?db=nucleotide&id=$uid&seq_start=$from&seq_stop=$to&strand=$s&rettype=fasta";
$result=get($url);
$r=$result;
$r=~s/>.+\n//;

$gc=$r=~tr/[GC]/gc/;
if (length $r !=0){$gc=$gc/length $r;}else {$gc="error";}

print "%GC=$gc\n$result\n";

}


}

