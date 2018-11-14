#!/bin/bash

# Correct MinION data using Canu

#$ -S /bin/bash
#$ -cwd
#$ -pe smp 24
#$ -l virtual_free=15.5G
#$ -l h=blacklace11.blacklace

Usage="sub_canu_correction.sh <reads.fq> <Genome_size[e.g.45m]> <outfile_prefix> <output_directory> [<specification_file.txt>]"
echo "$Usage"

# ---------------
# Step 1
# Collect inputs
# ---------------

FastqIn_1=$1
FastqIn_2=$2
Size=$3
Prefix=$4
OutDir=$5
AdditionalCommands=""
if [ $6 ]; then
  SpecFile=$6
  AdditionalCommands="-s $SpecFile"
fi
echo  "Running Canu with the following inputs:"
echo "FastqIn - $FastqIn1 $FastqIn2"
echo "Size - $Size"
echo "Prefix - $Prefix"
echo "OutDir - $OutDir"

CurPath=$PWD
WorkDir=/data2/scratch2/armita/SWD/canu

# ---------------
# Step 2
# Run Canu
# ---------------

mkdir -p $WorkDir
cd $WorkDir
Fastq1=$(basename $FastqIn_1)
Fastq2=$(basename $FastqIn_2)
cp $CurPath/$FastqIn_1 $WorkDir/$Fastq1
cp $CurPath/$FastqIn_2 $WorkDir/$Fastq2

canu \
  -correct \
  -useGrid=false \
  $AdditionalCommands \
  -overlapper=mhap \
  -utgReAlign=true \
  -d $WorkDir/assembly \
  -p $Prefix \
  genomeSize="$Size" \
  -nanopore-raw $Fastq1 \
  -nanopore-raw $Fastq2 \
  2>&1 | tee canu_run_log.txt

canu \
  -trim \
  -useGrid=false \
  $AdditionalCommands \
  -overlapper=mhap \
  -utgReAlign=true \
  -d $WorkDir/assembly \
  -p $Prefix \
  genomeSize="$Size" \
  -nanopore-corrected assembly/$Prefix.correctedReads.fasta.gz \
  2>&1 | tee canu_run_log.txt

  # canu \
  #   -correct \
  #   -useGrid=false \
  #   $AdditionalCommands \
  #   -overlapper=mhap \
  #   -utgReAlign=true \
  #   -d $WorkDir/assembly \
  #   -p $Prefix \
  #   genomeSize="$Size" \
  #   -pacbio-raw $Fastq \
  #   2>&1 | tee canu_run_log.txt
  #
  # canu \
  #   -trim \
  #   -useGrid=false \
  #   $AdditionalCommands \
  #   -overlapper=mhap \
  #   -utgReAlign=true \
  #   -d $WorkDir/assembly \
  #   -p $Prefix \
  #   genomeSize="$Size" \
  #   -pacbio-corrected assembly/$Prefix.correctedReads.fasta.gz \
  #   2>&1 | tee canu_run_log.txt

mkdir -p $CurPath/$OutDir
cp canu_run_log.txt $CurPath/$OutDir/.
cp $WorkDir/assembly/* $CurPath/$OutDir/.
