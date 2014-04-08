#!/bin/sh
#$ -cwd -V
#$ -S /bin/sh
#$ -N mlst.sh

##############################################
# Parameters. Qsub parameters are intertwined, so edit both parameters at once.
##############################################

## output file is stdout, so be sure to use -o if using qsub

script=`basename $0`;
#$ -e mlst.sh.err 
logfile="mlst.sh.err"
#$ -pe smp 12
NUMCPUS=12

# non-qsub parameters
allele="abcZ bglA cat dapE dat ldh lhkA"
URL="http://www.pasteur.fr/cgi-bin/genopole/PF8/mlstdbnet.pl?page=alleles&format=FASTA&file=Lmono_profiles.xml&locus="

#####################################
# Done with config
#####################################
# Don't edit below here
#####################################
echo "Updating databases" >> $logfile
cd db >> /dev/null 2>&1;
if [ $? -gt 0 ]; then echo "ERROR: You need to run this from the main MLST directory; not from a subdirectory" >> $logfile; exit 1; fi;
(for i in $allele; do 
  if [ -e "db/$i.fasta.nin" ]; then
    continue;
  fi;
  wget "$URL$i" -O db/$i.fasta; 
  legacy_blast.pl formatdb -i db/$i.fasta -p F; 
done;) >> $logfile 2>&1
cd -;


echo "Performing BLASTn" >> $logfile
ls assemblies/*.fasta >> /dev/null 2>&1
if [ $? -gt 0 ]; then echo "ERROR: There is no assemblies/ directory with fasta files!" >> $logfile; exit 1; fi;
jobsRunning=0;
( for asm in assemblies/*.fasta; do

  (
  # blast each locus of a genome
  asm=`basename $asm .fasta`;
  echo "Blasting $asm" >> $logfile
  for i in $allele; do
    if [ -e blast/"$asm"_"$i".blast.out ]; then
      echo "blast/"$asm"_"$i".blast.out is already present. Skipping." >> $logfile
      continue;
    fi;
    # make the blast output file
    legacy_blast.pl blastall -p blastn -F F -d db/$i.fasta -i assemblies/$asm.fasta -m 8 -a 1 | sort -k12,12nr | head -n 1 2>blast/"$asm"_"$i".blast.err 1>blast/"$asm"_"$i".blast.out.tmp
    if [ $? -gt 0 ]; then echo "ERROR: PROBLEM WITH BLASTn" >> $logfile; exit 1; fi;
    mv blast/"$asm"_"$i".blast.out.tmp blast/"$asm"_"$i".blast.out >> $logfile 2>&1
    if [ $? -gt 0 ]; then exit 1; fi;
  done;
  ) &
  if [ $? -gt 0 ]; then exit 1; fi;

  # job control
  jobsRunning=$(($jobsRunning+1))
  if [ $jobsRunning -ge $NUMCPUS ]; then
    echo "Waiting on a batch of $NUMCPUS jobs to finish" >> $logfile;
    wait;
    if [ $? -gt 0 ]; then exit 1; fi;
  else
    continue;
  fi

  # reset how many jobs are running
  jobsRunning=0;
done; )
if [ $? -gt 0 ]; then exit 1; fi;


echo "Reading the results in blast/*.blast.out" >> $logfile
# read the blast results and print the table
( for asm in assemblies/*.fasta; do
  asm=`basename $asm .fasta`;
  (
    echo $asm;
    for i in $allele; do
      blastfile=blast/"$asm"_"$i".blast.out
      sort -k 12 -n -r $blastfile|head -1 || echo "-"
    done;
  ) | perl -lae 'my $score=0; $asm=<>; print $asm;for(<>){@F=split/\t/;$score+=$F[11];print "$F[1]";}print $score' | xargs echo
done) | sort -k 9 -n

echo "DONE!" >> $logfile;
