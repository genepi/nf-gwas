process FILTER_RESULTS {

  tag "${regenie_chromosomes.simpleName}"
  publishDir "${params.outdir}/results/tophits", mode: 'copy'

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path("${regenie_chromosomes.baseName}.filtered.sorted.gz"), emit: results_filtered

  """
  java -jar /opt/RegenieFilter.jar --input ${regenie_chromosomes} --limit ${params.annotation_min_log10p} --output ${regenie_chromosomes.baseName}.filtered
  #todo: CSVWriter for gzip
  gzip ${regenie_chromosomes.baseName}.filtered
  csvtk sort ${regenie_chromosomes.baseName}.filtered.gz -t -kLOG10P:nr | gzip >  ${phenotype}.regenie.filtered.sorted.gz
  """

}
