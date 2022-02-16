process FILTER_RESULTS {

  tag "${regenie_chromosomes.simpleName}"

  input:
    tuple val(phenotype), path(regenie_chromosomes)
    path regenie_filter_jar

  output:
    tuple val(phenotype), path("${regenie_chromosomes.baseName}.filtered*"), emit: results_filtered
    tuple val(phenotype), path("${regenie_chromosomes}"), emit: results

  """
  java -jar ${regenie_filter_jar} --input ${regenie_chromosomes} --limit ${params.annotation_min_log10p} --output ${regenie_chromosomes.baseName}.filtered
  #todo: CSVWriter for gzip
  gzip ${regenie_chromosomes.baseName}.filtered
  """

}
