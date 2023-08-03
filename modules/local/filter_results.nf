process FILTER_RESULTS {

  tag "${regenie_chromosomes.simpleName}"
  publishDir "${params.outdir}/results/tophits", mode: 'copy'

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path("${regenie_chromosomes.baseName}.filtered*"), emit: results_filtered

  """
  java -jar /opt/RegenieFilter.jar --sep '\t' --input ${regenie_chromosomes} --limit ${params.annotation_min_log10p} --output ${regenie_chromosomes.baseName}.tmp
  #todo: CSVWriter for gzip
  csvtk sort ${regenie_chromosomes.baseName}.tmp -t -kLOG10P:nr | gzip >  ${phenotype}.regenie.filtered.gz
  rm ${regenie_chromosomes.baseName}.tmp
  """

}