import csv
import os
import pandas as pd
import glob

try:
    merged_coverage = pd.read_csv('merged_downstream_coverage_uniq.tsv', sep='\t')
    x=1

except IOError as e:
    print(os.strerror(e.errno))
    data = pd.DataFrame()
    first = 0

    for file in os.listdir(os.getcwd()):
        if file.endswith("uniqdscoverage.bed"):
            name = file.split('uniqdscoverage.bed')[0]
            if first == 0:
                frame = pd.read_csv(file, sep='\t', names=['chrom','start','end', 'id', 'numreads', 'coverage', 'regsize', 'ratio'])
                data[['chrom','start','end',name+'_numreads',name+'_coverage']] = frame[['chrom','start','end','numreads','coverage']]
                first = 1
            else:
                frame = pd.read_csv(file, sep='\t', names=['chrom', 'start', 'end', 'id', 'numreads', 'coverage', 'regsize','ratio'])
                data[[name + '_numreads', name + '_coverage']] = frame[['numreads', 'coverage']]

    data.to_csv('merged_downstream_coverage_uniq.tsv', sep='\t',index=False)