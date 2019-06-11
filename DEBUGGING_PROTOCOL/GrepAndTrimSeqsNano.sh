module load bio-tools

for fastqgz in *fastq.gz
do
	gunzip -c $fastqgz | fastq-grep "AACAGTCCCTTAAGCGGAGCCCTATAGTG" -b -t > $fastqgz.trimmed
	fastq-uniq $fastqgz.trimmed > $fastqgz.trimmed.uniq
done


