process SNP_PRUNING {

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file)
  output:
    tuple val("${genotyped_plink_filename}.pruned"), path("${genotyped_plink_filename}.pruned.bim"), path("${genotyped_plink_filename}.pruned.bed"),path("${genotyped_plink_filename}.pruned.fam"), emit: genotypes_pruned

  """
  # Prune, filter and convert to plink
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --double-id --maf ${params.prune_maf} \
    --indep-pairwise ${params.prune_window_kbsize} ${params.prune_step_size} ${params.prune_r2_threshold} \
    --out ${genotyped_plink_filename} \
    --threads ${task.cpus} \
    --memory ${task.memory.toMega()}
      
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --extract ${genotyped_plink_filename}.prune.in \
    --double-id \
    --make-bed \
    --out ${genotyped_plink_filename}.pruned \
    --threads ${task.cpus} \
    --memory ${task.memory.toMega()}
  """

}
