process MERGE_RESULTS {

  publishDir "${params.outdir}/results", mode: 'copy'
  tag "${phenotype}"

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path ("${phenotype}.regenie.gz"), emit: results_merged
    path "${phenotype}.regenie.gz.tbi"

  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs cat | zgrep -hE 'CHROM' | gzip > header.gz
  ls *_${phenotype}.regenie.gz | xargs cat | zgrep -hE '^[0-9]' | gzip > ${phenotype}.regenie.tmp.gz
  cat header.gz ${phenotype}.regenie.tmp.gz > ${phenotype}.regenie.tmp2.gz
  rm ${phenotype}.regenie.tmp.gz
  zcat ${phenotype}.regenie.tmp2.gz | sed 's/ /\t/g' | bgzip -c > ${phenotype}.regenie.gz
  rm ${phenotype}.regenie.tmp2.gz
  tabix -f -b 2 -e 2 -s 1 -S 1 ${phenotype}.regenie.gz

  """

}
