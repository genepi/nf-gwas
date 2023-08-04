process REGENIE_STEP1_RUN_CHUNK {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: "chunks_job_${chunk}.log"
  publishDir "${params.outdir}/chunks", mode: 'copy', pattern: "chunks_job${chunk}*"

  input:
    tuple val(chunk), path(master), path(chunk_snpllist), val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file),  path(snplist), path(id), path(phenotypes_file), path(covariates_file), path(condition_list_file)

  output:
    path "chunks_job${chunk}*", emit: regenie_step1_out
    path "chunks_job_${chunk}.log", emit: regenie_step1_out_log

  script:
  def covariants = covariates_file ? "--covarFile $covariates_file" : ''
  def quant_covariants = params.covariates_columns ? "--covarColList ${params.covariates_columns}" : ''
  def cat_covariants = params.covariates_cat_columns ? "--catCovarList ${params.covariates_cat_columns}" : ''
  def deleteMissings = params.phenotypes_delete_missings  ? "--strict" : ''
  def apply_rint = params.phenotypes_apply_rint ? "--apply-rint" : ''
  def forceStep1 = params.regenie_force_step1  ? "--force-step1" : ''
  def refFirst = params.regenie_ref_first  ? "--ref-first" : ''
  def condition_list = params.regenie_condition_list ? "--condition-list $condition_list_file" : ''
  """
  # qcfiles path required for keep and extract (but not actually set below)
  regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --extract ${snplist} \
    --keep ${id} \
    --phenoFile ${phenotypes_file} \
    --phenoColList  ${params.phenotypes_columns} \
    $covariants \
    $quant_covariants \
    $cat_covariants \
    $condition_list \
    $deleteMissings \
    $apply_rint \
    $forceStep1 \
    $refFirst \
    --bsize ${params.regenie_bsize_step1} \
    ${params.phenotypes_binary_trait ? '--bt' : ''} \
    --lowmem \
    --gz \
    --lowmem-prefix tmp_rg \
    --threads ${task.cpus} \
    --run-l0 ${master},${chunk} \
    --out chunks_job_${chunk} \
    --use-relative-path
  """

}
