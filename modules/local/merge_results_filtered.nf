process MERGE_RESULTS_FILTERED {

  tag "${phenotype}"
  publishDir "${params.outdir}/results/tophits", mode: 'copy'

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path("${phenotype}.regenie.filtered.gz"), emit: results_filtered_merged


  """
  csvtk concat -t ${regenie_chromosomes} | gzip > ${phenotype}_merged.gz
  csvtk sort ${phenotype}_merged.gz -t -kLOG10P:nr > ${phenotype}.regenie.filtered.gz
  """

}
