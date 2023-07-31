process FILTER_RESULTS {

  tag "${regenie_chromosomes.simpleName}"

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path("${regenie_chromosomes.baseName}.filtered*"), emit: results_filtered
    tuple val(phenotype), path("${regenie_chromosomes}"), emit: results

  """
  java -jar /opt/RegenieFilter.jar --input ${regenie_chromosomes} --limit ${params.annotation_min_log10p} --output ${regenie_chromosomes.baseName}.filtered
  #todo: CSVWriter for gzip
  gzip ${regenie_chromosomes.baseName}.filtered
  """

}