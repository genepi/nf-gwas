process MERGE_RESULTS {

    publishDir "${params.pubDir}/results", mode: 'copy'
    tag "${phenotype}"

    input:
    tuple val(phenotype), path(regenie_chromosomes)

    output:
    tuple val(phenotype), path ("${phenotype}.regenie.gz"), emit: results_merged
    path "${phenotype}.regenie.gz", emit: results_merged_regenie_only
    path "${phenotype}.regenie.gz.tbi"

    """
    java -jar /opt/genomic-utils.jar csv-concat \
        --separator ' ' \
        --output-sep '\t' \
        --gz \
        --output ${phenotype}.regenie.tmp.gz \
        ${regenie_chromosomes}

    zcat ${phenotype}.regenie.tmp.gz | awk 'NR<=1{print \$0;next}{print \$0| "sort -n -k1 -k2 -T \$PWD"}' | bgzip -c > ${phenotype}.regenie.gz  
    tabix -f -b 2 -e 2 -s 1 -S 1 ${phenotype}.regenie.gz
    """

}