import csv
import os

try:
    csv_file_pos = open("downstreamTRNApos.bed", 'r')
    csv_file_neg = open("downstreamTRNAneg.bed", 'r')

except IOError as e:
    print(os.strerror(e.errno))
    with open('S288c_fixed.gff') as tRNAs:
        tRNA_reader = csv.reader(tRNAs, delimiter='\t')
        csv_file_pos = open("downstreamTRNApos.bed", 'w')
        csv_file_neg = open("downstreamTRNAneg.bed", 'w')
        for l, line in enumerate(tRNA_reader):
            if line[2] == "tRNA_gene":
                if line[6] == "+":
                    csv_file_pos.write(line[0])
                    csv_file_pos.write('\t')
                    csv_file_pos.write(str(line[4]))
                    csv_file_pos.write('\t')
                    csv_file_pos.write(str(int(line[4]) + 1000))
                    csv_file_pos.write('\t')
                    gene_info = line[8].split(';')
                    ID_raw = gene_info[0]
                    id_tag = ID_raw.split('=')[1]
                    id_tag = id_tag.replace('%28', '(', 1)
                    id_tag = id_tag.replace('%29', ')', 1)
                    csv_file_pos.write(id_tag)
                    csv_file_pos.write('\n')
                elif line[6] == "-":
                    csv_file_neg.write(line[0])
                    csv_file_neg.write('\t')
                    csv_file_neg.write(str(int(line[3])-1000))
                    csv_file_neg.write('\t')
                    csv_file_neg.write(str(int(line[3])-1))
                    csv_file_neg.write('\t')
                    gene_info = line[8].split(';')
                    ID_raw = gene_info[0]
                    id_tag = ID_raw.split('=')[1]
                    id_tag = id_tag.replace('%28', '(', 1)
                    id_tag = id_tag.replace('%29', ')', 1)
                    csv_file_neg.write(id_tag)
                    csv_file_neg.write('\n')
