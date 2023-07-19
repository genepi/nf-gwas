process MERGE_RESULTS_FILTERED {

  tag "${phenotype}"
  publishDir "${params.outdir}/results/tophits", mode: 'copy'

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path("${phenotype}.regenie.filtered.gz"), emit: results_filtered_merged


  """
  # get header from first line of first file
  echo ${phenotype}
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs zcat | grep -hE 'CHROM' | gzip > header.gz
  # sort by p-value
  zcat ${regenie_chromosomes} | grep -hE '^(chr)?[0-9]' | sort -k13 --general-numeric-sort --reverse -T \$PWD | gzip > ${phenotype}.regenie.tmp.gz
  cat header.gz ${phenotype}.regenie.tmp.gz > ${phenotype}.regenie.filtered.gz
  rm ${phenotype}.regenie.tmp.gz
  """

}
