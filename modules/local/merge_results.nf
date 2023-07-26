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
  csvtk concat -d \$' ' -T ${regenie_chromosomes} | gzip > ${phenotype}_merged.gz
  zcat ${phenotype}_merged.gz | awk 'NR<=1{print \$0;next}{print \$0| "sort -n -k1 -k2 -T \$PWD"}' | bgzip -c > ${phenotype}.regenie.gz
  tabix -f -b 2 -e 2 -s 1 -S 1 ${phenotype}.regenie.gz
  """

}
