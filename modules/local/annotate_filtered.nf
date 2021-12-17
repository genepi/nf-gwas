process ANNOTATE_FILTERED {

  publishDir "${params.outdir}/results/tophits", mode: 'copy'

  input:
    tuple val(phenotype), path(regenie_merged)
    path genes_hg19
    path genes_hg38

  output:
    tuple val(phenotype), path("${regenie_merged.baseName}.annotated.txt.gz"), emit: annotated_ch

  script:
  def genes = params.genotypes_build == 'hg19' ? "${genes_hg19}" : "${genes_hg38}"

  """
  #!/bin/bash
  set -e
  (zcat ${regenie_merged} | head -n 1 && zcat ${regenie_merged} | tail -n +2 | sort -T $PWD/work -k12 --general-numeric-sort --reverse) | gzip > ${regenie_merged.baseName}.sorted.gz
  # sort lexicographically (required by bedtools)
  zcat ${regenie_merged.baseName}.sorted.gz | awk 'NR == 1; NR > 1 {print \$0 | "sort -k1,1 -k2,2n"}' > ${regenie_merged.baseName}.sorted.txt
  # duplicate 2nd column (to write valid bed)
  awk 'BEGIN{} {\$2 = \$2 OFS \$2} 1' OFS='\t' ${regenie_merged.baseName}.sorted.txt > ${regenie_merged.baseName}.sorted.bed
  rm ${regenie_merged.baseName}.sorted.txt
  # run bedtools
  bedtools closest -a ${regenie_merged.baseName}.sorted.bed -b ${genes} -d -header > ${regenie_merged.baseName}.annotated.bed
  rm ${regenie_merged.baseName}.sorted.bed
  # remove duplication of 2nd column
  cut -f1,3- ${regenie_merged.baseName}.annotated.bed > ${regenie_merged.baseName}.annotated.fixed.bed
  rm ${regenie_merged.baseName}.annotated.bed
  # write extended header
  cat ${regenie_merged.baseName}.annotated.fixed.bed | head -n 1 | sed ' 1 s/.*/&\tGENE_CHROMOSOME\tGENE_START\tGENE_END\tGENE_NAME\tDISTANCE/' > ${regenie_merged.baseName}.annotated.header.bed
  sed 1,1d ${regenie_merged.baseName}.annotated.fixed.bed  > ${regenie_merged.baseName}.annotated.noheader.txt
  rm ${regenie_merged.baseName}.annotated.fixed.bed
  # combine files
  cat ${regenie_merged.baseName}.annotated.header.bed ${regenie_merged.baseName}.annotated.noheader.txt > ${regenie_merged.baseName}.annotated.merged.bed
  rm ${regenie_merged.baseName}.annotated.header.bed
  # sort by p-value again
  (cat  ${regenie_merged.baseName}.annotated.merged.bed | head -n 1 && cat ${regenie_merged.baseName}.annotated.merged.bed | tail -n +2 | sort -k12 --general-numeric-sort --reverse) | gzip > ${regenie_merged.baseName}.annotated.txt.gz
  """

}
