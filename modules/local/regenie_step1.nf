process REGENIE_STEP1 {

publishDir "${params.outdir}/logs", mode: 'copy', pattern: 'regenie_step1_out.log'
cpus "${params.cpus}"

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)
    path snplist
    path id
    path phenotypes_file
    path covariates_file

  output:
    path "regenie_step1_out*", emit: regenie_step1_out
    path "regenie_step1_out.log", emit: regenie_step1_out_log

  script:
  def covariants = covariates_file.name != 'NO_COV_FILE' ? "--covarFile $covariates_file --covarColList ${params.covariates_columns}" : ''
  def deleteMissings = params.phenotypes_delete_missings  ? "--strict" : ''
  def forceStep1 = params.regenie_force_step1  ? "--force-step1" : ''
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
    $deleteMissings \
    $forceStep1 \
    --bsize ${params.regenie_bsize_step1} \
    ${params.phenotypes_binary_trait == true ? '--bt' : ''} \
    --lowmem \
    --gz \
    --lowmem-prefix tmp_rg \
    --threads ${task.cpus} \
    --out regenie_step1_out
  """

}
