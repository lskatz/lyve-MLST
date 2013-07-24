#!/bin/sh

# parameters
logfile="/dev/stderr"
allele="abcZ bglA cat dapE dat ldh lhkA"

# Don't edit below here
#####################################
echo "Updating databases" >& $logfile
cd db;
if [ $? -gt 0 ]; then echo "ERROR: You need to run this from the main MLST directory; not from a subdirectory"; exit 1; fi;
(for i in $allele; do wget 'http://www.pasteur.fr/cgi-bin/genopole/PF8/mlstdbnet.pl?page=alleles&format=FASTA&locus='$i'&file=Lmono_profiles.xml' -O db/$i.fasta; legacy_blast.pl formatdb -i db/$i.fasta -p F; done;) >& $logfile
cd -;


echo "Performing BLASTn" >& $logfile
ls assemblies/*.fasta >& /dev/null
if [ $? -gt 0 ]; then echo "ERROR: There is no assemblies/ directory with fasta files!"; exit 1; fi;
( for asm in assemblies/*.fasta; do
  asm=`basename $asm .fasta`;
  (
    echo $asm >& $logfile
    for i in $allele; do
      if [ -e blast/"$asm"_"$i".blast.out ]; then
        echo blast/"$asm"_"$i".blast.out is already present. Skipping. >& $logfile
        continue;
      fi;
      # make the blast output file
      legacy_blast.pl blastall -p blastn -F F -d db/$i.fasta -i assemblies/$asm.fasta -m 8 -a 12 2>blast/"$asm"_"$i".blast.err 1>blast/"$asm"_"$i".blast.out
      # make the results read-only
      chmod 444 blast/"$asm"_"$i".blast.err blast/"$asm"_"$i".blast.out; 
      # chmod 644 filename # to make it read/write again
    done;
  );
done )


echo "Reading the results in blast/*.blast.out" >& $logfile
# read the blast results and print the table
( for asm in assemblies/*.fasta; do
  asm=`basename $asm .fasta`;
  (
    echo $asm;
    for i in $allele; do
      blastfile=blast/"$asm"_"$i".blast.out
      sort -k 12 -n -r $blastfile|head -1
    done;
  ) | perl -lae 'my $score=0; $asm=<>; print $asm;for(<>){@F=split/\t/;$score+=$F[11];print "$F[1]";}print $score' | xargs echo
done) | sort -k 9 -n

