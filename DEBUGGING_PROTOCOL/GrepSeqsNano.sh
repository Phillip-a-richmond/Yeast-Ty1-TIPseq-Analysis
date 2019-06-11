module load bio-tools

echo "Fastq	TotalReads	AACA	AANA	AACATACCACCCATAATGTAATAGATCT	AANATACCACCCATAATGTAATAGATCT	AACAGTCCCTTAAGCGGAGCCCTATAGTG	AANAGTCCCTTAAGCGGAGCCCTATAGTG"
for fastqgz in *fastq.gz
do
	linecount=`gunzip -c $fastqgz | wc -l`
	readcount=`expr $linecount / 4`
	seqA=`gunzip -c $fastqgz | fastq-grep "^AACA" $fastq -c`
	seqA1=`gunzip -c $fastqgz | fastq-grep "^AANA" $fastq -c`
	seq1=`gunzip -c $fastqgz | fastq-grep "AACATACCACCCATAATGTAATAGATCT" $fastq -c`
	seq2=`gunzip -c $fastqgz | fastq-grep "AANATACCACCCATAATGTAATAGATCT" $fastq -c`
	seq3=`gunzip -c $fastqgz | fastq-grep "AACAGTCCCTTAAGCGGAGCCCTATAGTG" $fastq -c`
	seq4=`gunzip -c $fastqgz | fastq-grep "AANAGTCCCTTAAGCGGAGCCCTATAGTG" $fastq -c`
	echo "$fastqgz	$readcount	$seqA	$seqA1	$seq1	$seq2	$seq3	$seq4"
done


