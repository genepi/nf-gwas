process PRUNE_GENOTYPED {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.pruned.log'
  label 'process_plink2'

  input:
    tuple val(genotyped_qc_filename), path(genotyped_qc_bim_file), path(genotyped_qc_bed_file), path(genotyped_qc_fam_file)
  output:
    tuple val("${genotyped_qc_filename}.pruned"), path("${genotyped_qc_filename}.pruned.bim"), path("${genotyped_qc_filename}.pruned.bed"),path("${genotyped_qc_filename}.pruned.fam"), emit: genotypes_pruned_ch
    path "${genotyped_qc_filename}.pruned.log"
  """
  # Prune, filter and convert to plink
  plink2 \
    --bfile ${genotyped_qc_filename} \
    --double-id --maf ${params.prune_maf} \
    --indep-pairwise ${params.prune_window_kbsize} ${params.prune_step_size} ${params.prune_r2_threshold} \
    --out ${genotyped_qc_filename} \
    --threads ${task.cpus} \
    --memory ${task.memory.toMega()}
  plink2 \
    --bfile ${genotyped_qc_filename} \
    --extract ${genotyped_qc_filename}.prune.in \
    --double-id \
    --make-bed \
    --out ${genotyped_qc_filename}.pruned \
    --threads ${task.cpus} \
    --memory ${task.memory.toMega()}
  """

}
