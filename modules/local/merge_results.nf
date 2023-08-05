process MERGE_RESULTS {

  publishDir "${params.outdir}/results", mode: 'copy'
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
  gunzip -c ${phenotype}.regenie.tmp.gz | bgzip -c > ${phenotype}.regenie.gz
  tabix -f -b 2 -e 2 -s 1 -S 1 ${phenotype}.regenie.gz

  """

}