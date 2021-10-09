process TOPHITS {

  input:
    tuple val(phenotype), path(regenie_merged)

  output:
    tuple val(phenotype), path("${regenie_merged.baseName}.tophits.gz"), emit: tophits_ch


  """
  #!/bin/bash
  set -e
  (zcat ${regenie_merged} | head -n 1 && zcat ${regenie_merged} | tail -n +2 | sort -T $PWD/work -k12 --general-numeric-sort --reverse) | gzip > ${regenie_merged.baseName}.sorted.gz
  zcat ${regenie_merged.baseName}.sorted.gz | head -n ${params.tophits} | gzip > ${regenie_merged.baseName}.tophits.gz
  rm ${regenie_merged.baseName}.sorted.gz
  """

}
