process ANNOTATE_RESULTS {

    input:
    tuple val(phenotype), path(regenie_merged), path(regenie_dict)
    path genes_hg19
    path genes_hg38
    tuple path(rsids_file), path(rsids_tbi_file)
    val hg_build_source

    output:
    tuple val(phenotype), path("${regenie_merged.baseName}.split_*regenie.gz"), emit: annotated_ch

    script:
    def genes = hg_build_source == 'hg19' ? "${genes_hg19}" : "${genes_hg38}"
    """
    #!/bin/bash
    set -e

    # annotate with genes
    java -jar /opt/genomic-utils.jar annotate-genes \
        --input ${regenie_merged} \
        --sep ' ' \
        --chr CHROM \
        --pos GENPOS \
        --anno ${genes} \
        --anno-columns GENE_CHROMOSOME,GENE_START,GENE_END,GENE_NAME,GENE_DISTANCE \
        --anno-chr GENE_CHROMOSOME \
        --anno-start GENE_START \
        --anno-end GENE_END \
        --output-sep ' ' \
        --output-gzip \
        --output ${regenie_merged.baseName}.genes.txt.gz

    # annotate rsids with tabix-merge if file is provided
    if [ -z ${rsids_file} ]
    then
        mv ${regenie_merged.baseName}.genes.txt.gz ${regenie_merged.baseName}.annotated.txt.gz
    else
        java -jar /opt/genomic-utils.jar annotate \
            --input ${regenie_merged.baseName}.genes.txt.gz \
            --sep ' ' \
            --chr CHROM \
            --pos GENPOS \
            --ref ALLELE0 \
            --alt ALLELE1 \
            --anno ${rsids_file} \
            --anno-columns REF,ALT,RSID \
            --strategy CHROM_POS_ALLELES \
            --output-sep ' ' \
            --output-gzip \
            --output ${regenie_merged.baseName}.annotated.txt.gz
    fi
  
    java -jar /opt/genomic-utils.jar regenie-split \
        --input ${regenie_merged.baseName}.annotated.txt.gz \
        --dict ${regenie_dict} \
        --output ${regenie_merged.baseName}.split_
    """
}
