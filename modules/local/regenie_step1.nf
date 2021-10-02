process REGENIE_STEP1 {

  //publishDir "$outdir/02_regenie_step1", mode: 'copy'

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)
    path phenotype_file
    path qcfiles
    path covariate_file

  output:
    path "fit_bin_out*", emit: fit_bin_out_ch
    path "fit_bin_out*log", emit: fit_bin_log_ch

  script:
  def covariants = covariate_file.name != 'NO_COV_FILE' ? "--covarFile $covariate_file --covarColList ${params.covariates_columns}" : ''
  def deleteMissings = params.phenotypes_delete_missings  ? "--strict" : ''
  """
  regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --extract ${genotyped_plink_filename}.qc.snplist \
    --keep ${genotyped_plink_filename}.qc.id \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypes_columns} \
    $covariants \
    $deleteMissings \
    --bsize ${params.regenie_bsize_step1} \
    ${params.phenotypes_binary_trait == true ? '--bt' : ''} \
    --lowmem \
    --gz \
    --lowmem-prefix tmp_rg \
    --threads ${params.threads} \
    --out fit_bin_out
  """

}
