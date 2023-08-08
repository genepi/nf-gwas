process REGENIE_STEP1_SPLIT {

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)
    path snplist
    path id
    path phenotypes_file
    path covariates_file
    path condition_list_file

  output:
    tuple path("chunks.master"), path("chunks*.snplist"), val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file), path(snplist), path(id), path(phenotypes_file), path(covariates_file), path(condition_list_file), emit: chunks
    path("chunks.master"), emit: master

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
    --split-l0 chunks,${params.genotypes_prediction_chunks} \
    --out chunks
  """

}
