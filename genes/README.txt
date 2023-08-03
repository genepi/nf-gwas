# Gene Annotation used from GENCODE

Source: https://www.gencodegenes.org/

## Prepare data

use genomic-utils and command `prepare-annotate`

### hg19

We use [v32](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/) to be compatible with most other tools:

```
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/GRCh37_mapping/gencode.v32lift37.annotation.gff3.gz
java -jar genomic-utils.jat preapre-annotate \
  --input gencode.v32lift37.annotation.gff3.gz \
  --output genes.hg19.csv
```

### hg38

We use [v32](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/) to be compatible with most other tools:

```
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_32/gencode.v32.annotation.gff3.gz
java -jar genomic-utils.jat preapre-annotate \
  --input gencode.v32.annotation.gff3.gz \
  --output genes.hg38.csv
```