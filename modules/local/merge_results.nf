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
  # get header from first line of first file
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs zcat | grep -hE '^CHROM' | gzip > header.gz
  # grep all lines not starting with 'CHROM' pattern and sort them by pos
  zgrep -hE '^(chr)?[0-9]' ${regenie_chromosomes} | sort -n -k1 -k2 -T \$PWD | gzip > ${phenotype}.regenie.tmp.gz
  cat header.gz ${phenotype}.regenie.tmp.gz > ${phenotype}.regenie.tmp2.gz
  rm ${phenotype}.regenie.tmp.gz
  zcat ${phenotype}.regenie.tmp2.gz | sed 's/ /\t/g' | bgzip -c > ${phenotype}.regenie.gz
  rm ${phenotype}.regenie.tmp2.gz
  tabix -f -b 2 -e 2 -s 1 -S 1 ${phenotype}.regenie.gz
  """

}