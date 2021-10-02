process MERGE_RESULTS_FILTERED {

publishDir "${params.outdir}/regenie_results", mode: 'copy'
tag "${phenotype}"

  input:
  path regenie_chromosomes
  val phenotype

  output:
    path "${params.project}.*.regenie.filtered.gz", emit: regenie_merged_filtered_ch


  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs cat | zgrep -hE 'CHROM' | gzip > header.gz
  ls -1v  ${regenie_chromosomes} | ls *_${phenotype}.regenie.filtered.gz | xargs cat | zgrep -hE '^[0-9]' | gzip > chromosomes_data_${phenotype}.regenie.tmp.gz
  cat header.gz chromosomes_data_${phenotype}.regenie.tmp.gz > ${params.project}.${phenotype}.regenie.filtered.gz
  rm chromosomes_data_${phenotype}.regenie.tmp.gz
  """

}
