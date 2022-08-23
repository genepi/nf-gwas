process MERGE_RESULTS_FILTERED {

  tag "${phenotype}"

  input:
    tuple val(phenotype), path(regenie_chromosomes)

  output:
    tuple val(phenotype), path("${phenotype}.regenie.filtered.gz"), emit: results_filtered_merged


  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs zcat | grep -hE 'CHROM' | gzip > header.gz
  ls *_${phenotype}.regenie.filtered.gz | xargs zcat | grep -hEv 'CHROM' | sort -n -k1 -k2 -T ${PWD} | gzip > ${phenotype}.regenie.tmp.gz
  cat header.gz ${phenotype}.regenie.tmp.gz > ${phenotype}.regenie.filtered.gz
  rm ${phenotype}.regenie.tmp.gz
  """

}
