process ANNOTATE_TOPHITS {

publishDir "${params.outdir}/tophits", mode: 'copy'

  input:
  path tophits
  path genes_hg19
  path genes_hg38

  output:
  path "${tophits.baseName}.annotated.txt.gz", emit: annotated_ch

  script:
  def genes = params.genotypes_build == 'hg19' ? "${genes_hg19}" : "${genes_hg38}"

  """
  #!/bin/bash
  set -e
  # sort lexicographically (required by bedtools)
  zcat ${tophits} | awk 'NR == 1; NR > 1 {print \$0 | "sort -k1,1 -k2,2n"}' > ${tophits.baseName}.sorted.txt
  # duplicate 2nd column (to write valid bed)
  awk 'BEGIN{} {\$2 = \$2 OFS \$2} 1' OFS='\t' ${tophits.baseName}.sorted.txt > ${tophits.baseName}.sorted.bed
  rm ${tophits.baseName}.sorted.txt
  # run bedtools
  bedtools closest -a ${tophits.baseName}.sorted.bed -b ${genes} -d -header > ${tophits.baseName}.annotated.bed
  rm ${tophits.baseName}.sorted.bed
  # remove duplication of 2nd column
  cut -f1,3- ${tophits.baseName}.annotated.bed > ${tophits.baseName}.annotated.fixed.bed
  rm ${tophits.baseName}.annotated.bed
  # write extended header
  cat ${tophits.baseName}.annotated.fixed.bed | head -n 1 | sed ' 1 s/.*/&\tGENE_CHROMOSOME\tGENE_START\tGENE_END\tGENE_NAME\tDISTANCE/' > ${tophits.baseName}.annotated.header.bed
  sed 1,1d ${tophits.baseName}.annotated.fixed.bed  > ${tophits.baseName}.annotated.noheader.txt
  rm ${tophits.baseName}.annotated.fixed.bed
  # combine files
  cat ${tophits.baseName}.annotated.header.bed ${tophits.baseName}.annotated.noheader.txt > ${tophits.baseName}.annotated.merged.bed
  rm ${tophits.baseName}.annotated.header.bed
  # sort by p-value again
  (cat  ${tophits.baseName}.annotated.merged.bed | head -n 1 && cat ${tophits.baseName}.annotated.merged.bed | tail -n +2 | sort -k12 --general-numeric-sort --reverse) | gzip > ${tophits.baseName}.annotated.txt.gz
  """

}
