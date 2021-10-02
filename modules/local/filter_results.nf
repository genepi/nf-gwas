process FILTER_RESULTS {

//publishDir "$params.output/regenie_results", mode: 'copy'
tag "${regenie_chromosomes.baseName}"

  input:
  path regenie_chromosomes
  path regenie_filter_jar

  output:
  path "${regenie_chromosomes.baseName}.filtered*", emit: gwas_results_filtered_ch
  path "${regenie_chromosomes}", emit: gwas_results_unfiltered_ch

  """
  java -jar ${regenie_filter_jar} --input ${regenie_chromosomes} --limit ${params.min_pvalue} --output ${regenie_chromosomes.baseName}.filtered
  #todo: CSVWriter for gzip
  gzip ${regenie_chromosomes.baseName}.filtered
  """

}