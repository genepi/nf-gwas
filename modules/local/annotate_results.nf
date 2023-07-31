process ANNOTATE_RESULTS {

  input:
    tuple val(phenotype), path(regenie_merged), path(regenie_dict)
    path genes_hg19
    path genes_hg38
    tuple path(rsids_file), path(rsids_tbi_file)
    val hg_build_source
  output:
    tuple val(phenotype), path("${regenie_merged.baseName}.split_*regenie.gz"), emit: annotated_ch

  script:
  def genes = hg_build_source == 'hg19' ? "${genes_hg19}" : "${genes_hg38}"
  """
  #!/bin/bash
  set -e
  # sort lexicographically (required by bedtools)
  zcat ${regenie_merged} | awk 'NR == 1; NR > 1 {print \$0 | "sort -k1,1 -k2,2n"}' | awk 'BEGIN{} {\$2 = \$2 OFS \$2} 1' OFS='\t'  > ${regenie_merged.baseName}.sorted.bed
  # run bedtools
  bedtools closest -a ${regenie_merged.baseName}.sorted.bed -b ${genes} -d -header -t first > ${regenie_merged.baseName}.annotated.bed
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
   # annotate rsids with tabix-merge if file is provided
  if [ -z ${rsids_file} ]
    then
    mv ${regenie_merged.baseName}.annotated.merged.bed ${regenie_merged.baseName}.annotated.txt.gz
  else
    java -jar /opt/genomic-utils.jar annotate \
    --input ${regenie_merged.baseName}.annotated.merged.bed \
    --chr CHROM \
    --pos GENPOS \
    --ref ALLELE0 \
    --alt ALLELE1 \
    --anno ${rsids_file}\
    --anno-columns REF,ALT,RSID \
    --strategy CHROM_POS_ALLELES \
    --output-sep ' ' \
    --output ${regenie_merged.baseName}.annotated.txt
    gzip ${regenie_merged.baseName}.annotated.txt
  fi
  
  java -jar /opt/genomic-utils.jar regenie-split --input ${regenie_merged.baseName}.annotated.txt.gz --dict ${regenie_dict}  --output ${regenie_merged.baseName}.split_
  
  
  """

}
