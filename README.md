# SWD
Commands used in the assembly and annotation of Drosophila suzukii


This document details the commands used to assemble and annotate minion sequence data.

Note - all this work was performed in the directory:
/home/groups/harrisonlab/project_files/drosophila


# 0. Building of directory structure

### Minion Data

```bash
	ProjectDir=/home/groups/harrisonlab/project_files/drosophila
	mkdir -p $ProjectDir
```


Basecalling from the gridion was used:

```bash
ProjectDir=/home/groups/harrisonlab/project_files/drosophila
cd $ProjectDir

Organism=D.suzukii
Strain=WT3
OutDir=$ProjectDir/raw_dna/minion/$Organism/$Strain


Date=2018-06-13
RawDatDir1=/data/seq_data/minion/2018/Dsuzukii-1/GA10000
cat $RawDatDir1/*.fastq | gzip -cf > $OutDir/${Strain}_${Date}_albacore_v2.2.7.fastq.gz

Date=2018-06-19
RawDatDir2=/data/seq_data/minion/2018/Dsuzukii-2/GA10000
cat $RawDatDir2/*.fastq | gzip -cf > $OutDir/${Strain}_${Date}_albacore_v2.2.7.fastq.gz
```
<!--
Nanopolish index had problems with either the fastq or fast5 files from the
gridion - as such they were recalled and used for nanopolish later

```bash
	screen -a
	ssh nanopore@nanopore

	# upgrade albacore
	wget https://mirror.oxfordnanoportal.com/software/analysis/ont_albacore-2.2.7-cp34-cp34m-manylinux1_x86_64.whl
	~/.local/bin/read_fast5_basecaller.py --version
	pip3 install --user ont_albacore-2.2.7-cp34-cp34m-manylinux1_x86_64.whl --upgrade
	~/.local/bin/read_fast5_basecaller.py --version

	mkdir FoStatice_06-09-18
	cd FoStatice_06-09-18
	# Oxford nanopore Stocks4 run1
	Organism=F.oxysporum_fsp_statice
	Strain=Stat10
	Date=2018-05-15
	FlowCell="FLO-MIN106"
	Kit="SQK-RBK001"
	RawDatDir=/data/seq_data/minion/2018/20180504_Statice10-180501/Statice10-180501/GA10000
	OutDir=~/FoStatice_06-09-18/$Organism/$Strain/$Date
	mkdir -p $OutDir

	cd $OutDir
	~/.local/bin/read_fast5_basecaller.py \
	  --flowcell $FlowCell \
	  --kit $Kit \
	  --input $RawDatDir \
	  --recursive \
	  --worker_threads 24 \
	  --save_path albacore_v2.2.7 \
	  --output_format fastq,fast5 \
	  --reads_per_fastq_batch 4000

	cd ~/FoStatice_06-09-18
	cat $OutDir/albacore_v2.2.7/workspace/pass/unclassified/*.fastq | gzip -cf > ${Strain}_${Date}_albacore_v2.2.7.fastq.gz

	tar -cz -f ${Strain}_${Date}_albacore_v2.2.7.tar.gz $OutDir

	FinalDir=/data/scratch/nanopore_tmp_data/Alternaria/albacore_v2.2.7
	mkdir -p $FinalDir
	mv ${Strain}_${Date}_albacore_v2.2.7.* $FinalDir/.
	chmod +rw -R $FinalDir
```
 -->
<!--
### MiSeq data

```bash
  RawDatDir=/data/seq_data/miseq/2018/RAW/180716_M04465_0083_000000000-BM8CL/Data/Intensities/BaseCalls
  ProjectDir=/home/groups/harrisonlab/project_files/fusarium
  OutDir=$ProjectDir/raw_dna/paired/F.oxysporum_fsp_statice/Stat10
  mkdir -p $OutDir/F
  mkdir -p $OutDir/R
  cd $OutDir/F
  cp -s $RawDatDir/Stat10_S1_L001_R1_001.fastq.gz .
  cd $OutDir/R
  cp -s $RawDatDir/Stat10_S1_L001_R2_001.fastq.gz .
  cd $ProjectDir
``` -->


## Assembly

### Removal of adapters

Splitting reads and trimming adapters using porechop
```bash
	for RawReads in $(ls raw_dna/minion/*/*/*.fastq.gz); do
    Organism=$(echo $RawReads| rev | cut -f3 -d '/' | rev)
    Strain=$(echo $RawReads | rev | cut -f2 -d '/' | rev)
    echo "$Organism - $Strain"
  	OutDir=qc_dna/minion/$Organism/$Strain
  	ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/dna_qc
  	qsub $ProgDir/sub_porechop.sh $RawReads $OutDir
  done
```
<!--
#### QC of MiSeq data

programs:
  fastqc
  fastq-mcf
  kmc

Data quality was visualised using fastqc:
```bash
for RawData in $(ls raw_dna/paired/*/*/*/*.fastq.gz | grep 'statice'); do
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/dna_qc
echo $RawData;
qsub $ProgDir/run_fastqc.sh $RawData
done
```

```bash
for StrainPath in $(ls -d raw_dna/paired/*/* | grep 'statice'); do
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/rna_qc
IlluminaAdapters=/home/armita/git_repos/emr_repos/tools/seq_tools/ncbi_adapters.fa
ReadsF=$(ls $StrainPath/F/*.fastq*)
ReadsR=$(ls $StrainPath/R/*.fastq*)
echo $ReadsF
echo $ReadsR
qsub $ProgDir/rna_qc_fastq-mcf.sh $ReadsF $ReadsR $IlluminaAdapters DNA
done
``` -->

# Identify sequencing coverage

For Minion data:
```bash
for RawData in $(ls raw_dna/minion/*/*/*q.gz); do
echo $RawData;
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/dna_qc;
GenomeSz=220
OutDir=$(dirname $RawData)
qsub $ProgDir/sub_count_nuc.sh $GenomeSz $RawData $OutDir
done
```

```bash
  for StrainDir in $(ls -d raw_dna/minion/*/*); do
    Strain=$(basename $StrainDir)
    printf "$Strain\t"
    for File in $(ls $StrainDir/*.txt); do
      echo $(basename $File);
      cat $File | tail -n1 | rev | cut -f2 -d ' ' | rev;
    done | grep -v '.txt' | awk '{ SUM += $1} END { print SUM }'
  done
```
MinION coverage was:
```
WT3	56.07
```
<!--
For Miseq data:
```bash
for RawData in $(ls qc_dna/paired/*/*/*/*q.gz | grep 'statice'); do
echo $RawData;
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/dna_qc;
qsub $ProgDir/run_fastqc.sh $RawData;
GenomeSz=70
OutDir=$(dirname $RawData)
qsub $ProgDir/sub_count_nuc.sh $GenomeSz $RawData $OutDir
done
```

```bash
	for StrainDir in $(ls -d qc_dna/paired/*/* | grep 'lactucae'); do
		Strain=$(basename $StrainDir)
		printf "$Strain\t"
		for File in $(ls $StrainDir/*/*.txt); do
			echo $(basename $File);
			cat $File | tail -n1 | rev | cut -f2 -d ' ' | rev;
		done | grep -v '.txt' | awk '{ SUM += $1} END { print SUM }'
	done
```

Miseq coverage was:
```

```
 -->

### Read correction using Canu

```bash
Jobs=$(qstat | grep 'sub_pore' | wc -l)
while [ $Jobs -gt 0 ]; do
sleep 1m
printf "."
Jobs=$(qstat | grep 'sub_pore' | wc -l)
done		
printf "\n"
TrimReads1=$(ls qc_dna/minion/*/*/*_trim.fastq.gz | head -n1 | tail -n1)
TrimReads2=$(ls qc_dna/minion/*/*/*_trim.fastq.gz | head -n2 | tail -n1)
Organism=$(echo $TrimReads1 | rev | cut -f3 -d '/' | rev)
Strain=$(echo $TrimReads1 | rev | cut -f2 -d '/' | rev)
echo $TrimReads
OutDir=assembly/canu-1.6/$Organism/"$Strain"
ProgDir=/home/armita/git_repos/emr_repos/scripts/SWD/scripts
qsub $ProgDir/sub_canu_correct_SWD.sh $TrimReads1 $TrimReads2 220m $Strain $OutDir
```


### Assembly using SMARTdenovo

```bash
for CorrectedReads in $(ls assembly/canu-1.6/*/*/*.trimmedReads.fasta.gz ); do
Organism=$(echo $CorrectedReads | rev | cut -f3 -d '/' | rev)
Strain=$(echo $CorrectedReads | rev | cut -f2 -d '/' | rev)
Prefix="$Strain"_smartdenovo
OutDir=assembly/SMARTdenovo/$Organism/"$Strain"
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/SMARTdenovo
qsub $ProgDir/sub_SMARTdenovo.sh $CorrectedReads $Prefix $OutDir
done
```


Quast and busco were run to assess assembly quality:

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/*.dmo.lay.utg); do
  Strain=$(echo $Assembly | rev | cut -f2 -d '/' | rev)
  Organism=$(echo $Assembly | rev | cut -f3 -d '/' | rev)  
	echo "$Organism - $Strain"
  OutDir=$(dirname $Assembly)
	ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
  qsub $ProgDir/sub_quast.sh $Assembly $OutDir
	OutDir=gene_pred/busco/$Organism/$Strain/assembly
	BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/diptera_odb9)
	ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
	qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```


Error correction using racon:

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/*.dmo.lay.utg); do
Strain=$(echo $Assembly | rev | cut -f2 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
echo "$Organism - $Strain"
ReadsFq1=$(ls qc_dna/minion/*/$Strain/*q.gz | head -n1 | tail -n1)
ReadsFq2=$(ls qc_dna/minion/*/$Strain/*q.gz | head -n2 | tail -n1)
Iterations=10
OutDir=$(dirname $Assembly)"/racon_$Iterations"
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/racon
qsub $ProgDir/sub_racon_2libs.sh $Assembly $ReadsFq1 $ReadsFq2 $Iterations $OutDir
done
```


```bash
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/*.fasta | grep 'round_10'); do
OutDir=$(dirname $Assembly)
echo "" > tmp.txt
ProgDir=~/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/remove_contaminants
$ProgDir/remove_contaminants.py --keep_mitochondria --inp $Assembly --out $OutDir/racon_min_500bp_renamed.fasta --coord_file tmp.txt > $OutDir/log.txt
done
```

Quast and busco were run to assess the effects of racon on assembly quality:

```bash
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)  
OutDir=$(dirname $Assembly)
qsub $ProgDir/sub_quast.sh $Assembly $OutDir
done
```

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon*/*.fasta); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/ascomycota_odb9)
OutDir=gene_pred/busco/$Organism/$Strain/assembly
# OutDir=$(dirname $Assembly)
qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```
```bash
printf "Filename\tComplete\tDuplicated\tFragmented\tMissing\tTotal\n"
for File in $(ls gene_pred/busco/A*/*/assembly/*/short_summary_*.txt); do
FileName=$(basename $File)
Complete=$(cat $File | grep "(C)" | cut -f2)
Duplicated=$(cat $File | grep "(D)" | cut -f2)
Fragmented=$(cat $File | grep "(F)" | cut -f2)
Missing=$(cat $File | grep "(M)" | cut -f2)
Total=$(cat $File | grep "Total" | cut -f2)
printf "$FileName\t$Complete\t$Duplicated\t$Fragmented\t$Missing\t$Total\n"
done
```


## Nanopolish


```bash

for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
# Step 1 extract reads as a .fq file which contain info on the location of the fast5 files
# Note - the full path from home must be used

# Extract archived reads if required:
# CurDir=$PWD
# ScratchDir=/data/scratch/nanopore_tmp_data/20190122_drosophila/albacore
# ReadDir=/data2/scratch2/armita/FoN/raw_dna/nanopolish/$Organism/$Strain
# mkdir -p $ReadDir
# cd $ReadDir
# tar -zxvf $ScratchDir/Stat10_2018-05-15_albacore_v2.2.7.tar.gz
# cd $CurDir
Fast5Dir1=$(ls -d /data/seq_data/minion/2018/Dsuzukii-1/GA10000)
Fast5Dir2=$(ls -d /data/seq_data/minion/2018/Dsuzukii-2/GA10000)

ReadsFq=raw_dna/minion/$Organism/$Strain/${Strain}_appended.fastq.gz
cat $Fast5Dir1/*.fastq  $Fast5Dir2/*.fastq > $ReadsFq


nanopolish index -d $Fast5Dir1/reads -d $Fast5Dir2/reads $ReadsFq

OutDir=$(dirname $Assembly)/nanopolish
mkdir -p $OutDir
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/nanopolish
# submit alignments for nanoppolish
qsub $ProgDir/sub_minimap2_nanopolish.sh $Assembly $ReadsFq $OutDir/nanopolish
done
```


 Split the assembly into 50Kb fragments an submit each to the cluster for
 nanopolish correction

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
OutDir=$(dirname $Assembly)/nanopolish
ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz | grep -v 'Stat10_2018-05-15')
AlignedReads=$(ls $OutDir/nanopolish/reads.sorted.bam)

NanoPolishDir=/home/armita/prog/nanopolish/nanopolish/scripts
python $NanoPolishDir/nanopolish_makerange.py $Assembly --segment-length 50000 > $OutDir/nanopolish_range.txt

Ploidy=1
echo "nanopolish log:" > $OutDir/nanopolish_log.txt
for Region in $(cat $OutDir/nanopolish_range.txt); do
Jobs=$(qstat | grep 'sub_nanopo' | grep 'qw' | wc -l)
while [ $Jobs -gt 1 ]; do
sleep 1m
printf "."
Jobs=$(qstat | grep 'sub_nanopo' | grep 'qw' | wc -l)
done		
printf "\n"
echo $Region
echo $Region >> $OutDir/nanopolish_log.txt
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/nanopolish
qsub $ProgDir/sub_nanopolish_variants.sh $Assembly $ReadsFq $AlignedReads $Ploidy $Region $OutDir/$Region
done
done
```

A subset of nanopolish jobs needed to be resubmitted as the ran out of RAM

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
OutDir=$(dirname $Assembly)/nanopolish
# ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz | grep '2017-12-03')
ReadsFq=$(ls raw_dna/minion/*/$Strain/*.fastq.gz | grep -v 'Stat10_2018-05-15')
AlignedReads=$(ls $OutDir/nanopolish/reads.sorted.bam)

NanoPolishDir=/home/armita/prog/nanopolish/nanopolish/scripts
# python $NanoPolishDir/nanopolish_makerange.py $Assembly --segment-length 50000 > $OutDir/nanopolish_range.txt

Ploidy=1
echo "nanopolish log:" > $OutDir/nanopolish_high_mem_log.txt
ls -lh $OutDir/*/*.fa | grep -v ' 0 ' | cut -f8 -d '/' | sed 's/_consensus.fa//g' > $OutDir/files_present.txt
for Region in $(cat $OutDir/nanopolish_range.txt | grep -vwf "$OutDir/files_present.txt"); do
echo $Region
echo $Region >> $OutDir/nanopolish_high_mem_log.txt
Jobs=$(qstat | grep 'sub_nano_h' | grep 'qw' | wc -l)
while [ $Jobs -gt 1 ]; do
sleep 1m
printf "."
Jobs=$(qstat | grep 'sub_nano_h' | grep 'qw' | wc -l)
done		
printf "\n"
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/nanopolish
qsub $ProgDir/sub_nanopolish_variants_high_mem.sh $Assembly $ReadsFq $AlignedReads $Ploidy $Region $OutDir/$Region
done
done
```

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/racon_10/racon_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
OutDir=assembly/SMARTdenovo/$Organism/$Strain/nanopolish
mkdir -p $OutDir
# cat "" > $OutDir/"$Strain"_nanoplish.fa
NanoPolishDir=/home/armita/prog/nanopolish/nanopolish/scripts
InDir=$(dirname $Assembly)
python $NanoPolishDir/nanopolish_merge.py $InDir/nanopolish/*/*.fa > $OutDir/"$Strain"_nanoplish.fa

echo "" > tmp.txt
ProgDir=~/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/remove_contaminants
$ProgDir/remove_contaminants.py --keep_mitochondria --inp $OutDir/"$Strain"_nanoplish.fa --out $OutDir/"$Strain"_nanoplish_min_500bp_renamed.fasta --coord_file tmp.txt > $OutDir/log.txt
done
```

Quast and busco were run to assess the effects of nanopolish on assembly quality:

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/nanopolish/*_nanoplish_min_500bp_renamed.fasta | grep -e 'Stat10'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)  
# Quast
OutDir=$(dirname $Assembly)
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
qsub $ProgDir/sub_quast.sh $Assembly $OutDir
# Busco
BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/sordariomyceta_odb9)
OutDir=gene_pred/busco/$Organism/$Strain/assembly
ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```

```bash
  for File in $(ls gene_pred/busco/*/*/assembly/*/short_summary_*.txt); do
  Strain=$(echo $File| rev | cut -d '/' -f4 | rev)
  Organism=$(echo $File | rev | cut -d '/' -f5 | rev)
  Version=$(echo $File | rev | cut -d '/' -f2 | rev)
  Complete=$(cat $File | grep "(C)" | cut -f2)
  Single=$(cat $File | grep "(S)" | cut -f2)
  Fragmented=$(cat $File | grep "(F)" | cut -f2)
  Missing=$(cat $File | grep "(M)" | cut -f2)
  Total=$(cat $File | grep "Total" | cut -f2)
  echo -e "$Organism\t$Strain\t$Version\t$Complete\t$Single\t$Fragmented\t$Missing\t$Total"
  done
```


Remove unpacked fast5 files:

```bash
# FON129
rm -r /home/groups/harrisonlab/project_files/fusarium_ex_narcissus/home
# FON139
rm -r raw_dna/nanopolish/F.oxysporum_fsp_narcissi/FON139/home
```
<!--
### Pilon assembly correction

Assemblies were polished using Pilon

```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/nanopolish/*_nanoplish_min_500bp_renamed.fasta  | grep -e 'Stat10'); do
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
echo "$Organism - $Strain"
IlluminaDir=$(ls -d qc_dna/paired/*/$Strain)
TrimF1_Read=$(ls $IlluminaDir/F/*_trim.fq.gz | head -n1)
TrimR1_Read=$(ls $IlluminaDir/R/*_trim.fq.gz | head -n1)
OutDir=$(dirname $Assembly)/../pilon
Iterations=10
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/pilon
qsub $ProgDir/sub_pilon.sh $Assembly $TrimF1_Read $TrimR1_Read $OutDir $Iterations
done
```

Contigs were renamed
```bash
echo "" > tmp.txt
Assembly=$(ls assembly/SMARTdenovo/*/*/pilon/*.fasta | grep 'Stat10' | grep 'pilon_10')
OutDir=$(dirname $Assembly)
ProgDir=~/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/remove_contaminants
$ProgDir/remove_contaminants.py --keep_mitochondria --inp $Assembly --out $OutDir/pilon_min_500bp_renamed.fasta --coord_file tmp.txt > $OutDir/log.txt
```

Quast and busco were run to assess the effects of pilon on assembly quality:

```bash
ProgDir=/home/armita/git_repos/emr_repos/tools/seq_tools/assemblers/assembly_qc/quast
for Assembly in $(ls assembly/SMARTdenovo/*/*/pilon/*.fasta | grep 'FON_63' | grep 'pilon_min_500bp_renamed.fasta'); do
  Strain=$(echo $Assembly | rev | cut -f2 -d '/' | rev)
  Organism=$(echo $Assembly | rev | cut -f3 -d '/' | rev)  
  OutDir=$(dirname $Assembly)
  qsub $ProgDir/sub_quast.sh $Assembly $OutDir
done
```


```bash
for Assembly in $(ls assembly/SMARTdenovo/*/*/pilon/*.fasta | grep 'FON_63'); do
Strain=$(echo $Assembly | rev | cut -f3 -d '/' | rev)
Organism=$(echo $Assembly | rev | cut -f4 -d '/' | rev)
echo "$Organism - $Strain"
ProgDir=/home/armita/git_repos/emr_repos/tools/gene_prediction/busco
BuscoDB=$(ls -d /home/groups/harrisonlab/dbBusco/sordariomyceta_odb9)
OutDir=gene_pred/busco/$Organism/$Strain/assembly
qsub $ProgDir/sub_busco3.sh $Assembly $BuscoDB $OutDir
done
```


```bash
printf "Filename\tComplete\tDuplicated\tFragmented\tMissing\tTotal\n"
for File in $(ls gene_pred/busco/F*/*/assembly/*/short_summary_*.txt | grep 'FON_63'); do  
FileName=$(basename $File)
Complete=$(cat $File | grep "(C)" | cut -f2)
Duplicated=$(cat $File | grep "(D)" | cut -f2)
Fragmented=$(cat $File | grep "(F)" | cut -f2)
Missing=$(cat $File | grep "(M)" | cut -f2)
Total=$(cat $File | grep "Total" | cut -f2)
printf "$FileName\t$Complete\t$Duplicated\t$Fragmented\t$Missing\t$Total\n"
done
```
-->
