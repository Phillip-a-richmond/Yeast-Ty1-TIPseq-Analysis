#!/bin/bash

#SBATCH --account=def-wyeth

## Mail Options
#SBATCH --mail-user=prichmond@cmmt.ubc.ca
#SBATCH --mail-type=ALL

## CPU Usage
#SBATCH --mem=100G
#SBATCH --cpus-per-task=32
#SBATCH --time=4-0:00
#SBATCH --nodes=1

## Output and Stderr
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.error

#SBATCH --array=0-7%8

MACS2=~/.local/bin/macs2
CUTADAPT=~/.local/bin/cutadapt
NSLOTS=32

WORKING_DIR=/project/projects/def-wyeth/RICHMOND/MEASDAY/PROCESS/20150521/
RAW_DIR=/project/projects/def-wyeth/RICHMOND/MEASDAY/RAW_DATA/20190129/

Files=(${RAW_DIR}*gz)
IFS='/' read -a array <<< ${Files[$SLURM_ARRAY_TASK_ID]}
SampleR1Fastq=${array[-1]}
IFS='.' read -a array2 <<< "${SampleR1Fastq}"
SAMPLE_ID=${array2[0]}$array
FASTQR1=$RAW_DIR${SAMPLE_ID}.fastq.gz

echo $SAMPLE_ID
echo $FASTQR1

BWA_INDEX=/project/projects/def-wyeth/RICHMOND/MEASDAY/GENOME/S288c_BWA_Index
GENOME_FASTA=/project/projects/def-wyeth/RICHMOND/MEASDAY/GENOME/S288c.fa

# Load Modules
module load picard/2.1.1 
module load gatk/3.7 
module load bwa/0.7.15
module load samtools/1.3.1
module load bedtools
echo "Primary Analysis Started"
date

# Cut adapters from end of sequences
$CUTADAPT -g "^AACA" \
	$FASTQR1 \
	--discard-untrimmed \
	-o $FASTQR1.5primetrimmed.fastq \
	> $SAMPLE_ID.ssbstats.txt

$CUTADAPT -a "TAGTCCCTTAAGCGGAGCCCTATAG" \
	-m 20 \
	$FASTQR1.5primetrimmed.fastq \
	-o  $FASTQR1.5primetrimmed.3primetrimmed.fastq \
	> $SAMPLE_ID.adapterstats.txt


#Map with BWA
bwa mem $BWA_INDEX -M -t $NSLOTS -R "@RG\tID:$SAMPLE_ID\tSM:$SAMPLE_ID\tPL:illumina"  $FASTQR1.5primetrimmed.3primetrimmed.fastq  > $WORKING_DIR$SAMPLE_ID.sam
samtools view -F 0x900 -@ $NSLOTS -ubS $WORKING_DIR${SAMPLE_ID}.sam | samtools sort - -@ $NSLOTS  -T $WORKING_DIR${SAMPLE_ID}.sorted -O BAM -o $WORKING_DIR${SAMPLE_ID}.sorted.bam
samtools index $WORKING_DIR${SAMPLE_ID}.sorted.bam
samtools flagstat $WORKING_DIR${SAMPLE_ID}.sorted.bam > $WORKING_DIR${SAMPLE_ID}.sorted.bam.flagstat

# Remove duplicates to make a mapped.dedup.bam
# This is for finding reads that map ambiguously, where they are mapping to with 5' end
TMPDIR=$WORKING_DIR'picardtmp/'
mkdir $TMPDIR
java -jar $EBROOTPICARD/picard.jar MarkDuplicates I=$WORKING_DIR${SAMPLE_ID}.sorted.bam \
	 REMOVE_DUPLICATES=true TMP_DIR=$TMPDIR \
	 M=$WORKING_DIR${SAMPLE_ID}_uniq_DuplicateResults.txt \
	 O=$WORKING_DIR${SAMPLE_ID}_dupremoved.sorted.bam
# Index dup removed bam
samtools index $WORKING_DIR${SAMPLE_ID}_dupremoved.sorted.bam
samtools flagstat $WORKING_DIR${SAMPLE_ID}_dupremoved.sorted.bam > $WORKING_DIR${SAMPLE_ID}_dupremoved.sorted.bam.flagstat

## Remove non-unique mapping reads
samtools view -q 30  $WORKING_DIR${SAMPLE_ID}.sorted.bam -o $WORKING_DIR${SAMPLE_ID}_uniq.sorted.bam
samtools index $WORKING_DIR${SAMPLE_ID}_uniq.sorted.bam
samtools flagstat $WORKING_DIR${SAMPLE_ID}_uniq.sorted.bam > $WORKING_DIR${SAMPLE_ID}_uniq.sorted.bam.flagstat

# Picard MarkDuplicates
TMPDIR=$WORKING_DIR'picardtmp/'
mkdir $TMPDIR
java -jar $EBROOTPICARD/picard.jar MarkDuplicates I=$WORKING_DIR${SAMPLE_ID}_uniq.sorted.bam \
	 REMOVE_DUPLICATES=true TMP_DIR=$TMPDIR \
	 M=$WORKING_DIR${SAMPLE_ID}_uniq_DuplicateResults.txt \
	 O=$WORKING_DIR${SAMPLE_ID}_dupremoved_uniq.sorted.bam

samtools index $WORKING_DIR${SAMPLE_ID}_dupremoved_uniq.sorted.bam
samtools flagstat $WORKING_DIR${SAMPLE_ID}_dupremoved_uniq.sorted.bam > $WORKING_DIR${SAMPLE_ID}_dupremoved_uniq.sorted.bam.flagstat

# MACS2 call peak
$MACS2 callpeak \
        -n $SAMPLE_ID \
        -t $WORKING_DIR${SAMPLE_ID}_dupremoved_uniq.sorted.bam \
        --outdir $WORKING_DIR${SAMPLE_ID}_MACS2 \
        -B --SPMR \
	--nomodel \
	--broad \
	-q 0.005 \
	--fe-cutoff 3.0 \
        -f BAM \

# Clean Up
rm $WORKING_DIR$SAMPLE_ID.sam

