process ANNOTATE_TOPHITS {

publishDir "${params.outdir}/regenie_tophits_annotated", mode: 'copy'

  input:
  path tophits
  path genes_hg19
  path genes_hg38

  output:
  path "${tophits.baseName}.annotated.txt.gz", emit: annotated_ch

  def genes = params.genotypes_build == 'hg19' ? "${genes_hg19}" : "${genes_hg38}"

  """
  #!/bin/bash
  set -e
  # sort lexicographically
  zcat ${tophits} | awk 'NR == 1; NR > 1 {print \$0 | "sort -k1,1 -k2,2n"}' > ${tophits.baseName}.sorted.txt
  sed -e 's/ /\t/g'  ${tophits.baseName}.sorted.txt > ${tophits.baseName}.sorted.tabs.txt
  rm ${tophits.baseName}.sorted.txt
  # remove header line for cloest-features
  sed 1,1d ${tophits.baseName}.sorted.tabs.txt > ${tophits.baseName}.sorted.tabs.fixed.txt
  # save header line
  head -n 1 ${tophits.baseName}.sorted.tabs.txt > ${tophits.baseName}.header.txt
  rm ${tophits.baseName}.sorted.tabs.txt
  # create final header
  sed ' 1 s/.*/&\tGENE_CHROMOSOME\tGENE_START\tGENE_END\tGENE_NAME\tGENE_DISTANCE/' ${tophits.baseName}.header.txt > ${tophits.baseName}.header.fixed.txt
  closest-features --dist --delim '\t' --shortest ${tophits.baseName}.sorted.tabs.fixed.txt ${genes} > ${tophits.baseName}.closest.txt
  cat ${tophits.baseName}.header.fixed.txt ${tophits.baseName}.closest.txt > ${tophits.baseName}.closest.merged.txt
  rm ${tophits.baseName}.sorted.tabs.fixed.txt
  rm ${tophits.baseName}.header.fixed.txt
  rm ${tophits.baseName}.header.txt
  # sort by p-value again
  (cat ${tophits.baseName}.closest.merged.txt | head -n 1 && cat ${tophits.baseName}.closest.merged.txt | tail -n +2 | sort -k12 --general-numeric-sort --reverse) | gzip > ${tophits.baseName}.annotated.txt.gz
  rm ${tophits.baseName}.closest.merged.txt
  """

}
