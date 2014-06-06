#!/bin/bash

# sh fileBlast.sh

USAGE="Usage: `basename $0` file.fasta"

if [ $# -ne 1 ]
# check proper # of command line args.
then
    echo $USAGE
    exit 1
fi

filename="$1"

bsub -q long -R type==LINUX << EOF 
blastall -a 2 -p blastn -b 5 -v 10 -e 1e-20 -d "hum_rna hum_rna_new" -i "$filename" | gzip -9 > "$filename".humRNA_bln.gz 
EOF
bsub -q long -R type==LINUX << EOF 
blastall -a 2 -p blastn -b 5 -v 10 -e 1e-20 -d "vert_rna vert_rna_new" -i "$filename" | gzip -9 > "$filename".vertRNA_bln.gz 
EOF
bsub -q long -R type==LINUX << EOF 
blastall -a 2 -p blastn -b 5 -v 10 -e 1e-20 -d fln -i "$filename" | gzip -9 > "$filename".fln_bln.gz 
EOF

bsub -n 2 -q long -R type==LINUX << EOF 
blastall -a 2 -p blastx -F F -b 5 -v 10 -e 1e-05 -d /home2/mlyne/PROBESET/PROBES/DRG_CURRENT/allDrgCat.fasta -i "$filename" | gzip -9 > "$filename".drg_blx.gz  
EOF
bsub -n 2 -q long -R type==LINUX << EOF 
blastall -a 2 -p blastx -F F -b 5 -v 10 -e 1e-05 -d nrswiss -i "$filename" | gzip -9 > "$filename".sw_blx.gz  
EOF
bsub -n 2 -q long -R type==LINUX << EOF 
blastall -a 2 -p blastx -F F -b 5 -v 10 -e 1e-05 -d sptrembl -i "$filename" | gzip -9 > "$filename".tr_blx.gz  
EOF
bsub -n 2 -q long -R type==LINUX << EOF 
blastall -a 2 -p blastx -F F -b 5 -v 10 -e 1e-05 -d genpept -i "$filename" | gzip -9 > "$filename".genp_blx.gz 
EOF
bsub -n 2 -q long -R type==LINUX << EOF 
blastall -a 2 -p blastx -F F -b 5 -v 10 -e 1e-05 -d ensembl.pep -i "$filename" | gzip -9 > "$filename".ens_blx.gz  
EOF
bsub -q big -R type==LINUX << EOF 
blastall -a 2 -p blastn -b 5 -v 10 -e 1e-20 -d CRUZ -i "$filename" | gzip -9 > "$filename".cruz_bln.gz 
EOF
bsub -q big -R type==LINUX << EOF 
blastall -a 2 -p blastn -b 5 -v 10 -e 1e-20 -d GBI_PROM -i "$filename" | gzip -9 > "$filename".prom_bln.gz 
EOF

exit 0
