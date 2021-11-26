################################################################
 Gene Annotation used from https://github.com/statgen/encore
 ###############################################################

#download files
wget https://raw.githubusercontent.com/statgen/encore/master/anno/nearest_gene.GRCh37.bed
wget https://raw.githubusercontent.com/statgen/encore/master/anno/nearest_gene.GRCh38.bed

# required by bedtools
sort -k1,1 -k2,2n nearest_gene.GRCh37.bed > nearest_gene.GRCh37.sorted.bed
sort -k1,1 -k2,2n nearest_gene.GRCh38.bed > nearest_gene.GRCh38.sorted.bed
