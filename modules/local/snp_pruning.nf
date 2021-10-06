process SNP_PRUNING {

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file)
  output:
    tuple val("${params.project}.pruned"), path("${params.project}.pruned.bim"), path("${params.project}.pruned.bed"),path("${params.project}.pruned.fam"), emit: genotypes_pruned

  """
  # Prune, filter and convert to plink
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --double-id --maf ${params.prune_maf} \
    --indep-pairwise ${params.prune_window_kbsize} ${params.prune_step_size} ${params.prune_r2_threshold} \
    --out ${params.project}
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --extract ${params.project}.prune.in \
    --double-id \
    --make-bed \
    --out ${params.project}.pruned
  """

}
