process REGENIE_STEP2 {
	cpus "${params.threads}"
  tag "${filename}"

  input:
	  path fit_bin_out
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file)
    path phenotype_file
    path sample_file
    path covariate_file

  output:
    path "*regenie.gz", emit: regenie_step2_out
    path "${filename}*log", emit: regenie_step2_log_out
  script:
    def format = params.genotypes_imputed_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = params.genotypes_imputed_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file.name != 'NO_SAMPLE_FILE' ? "--sample $sample_file" : ''
    def test = "--test $params.regenie_test"
    def range = params.regenie_range != '' ? "--range $params.regenie_range" : ''
    def covariants = covariate_file.name != 'NO_COV_FILE' ? "--covarFile $covariate_file --covarColList ${params.covariates_columns}" : ''
    def deleteMissingData = params.phenotypes_delete_missings  ? "--strict" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""


  """
  regenie \
    --step 2 \
    $format ${filename}${extension} \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypes_columns} \
    --bsize ${params.regenie_bsize_step2} \
    ${params.phenotypes_binary_trait ? '--bt  --firth 0.01 --approx' : ''} \
    --pred fit_bin_out_pred.list \
    --threads ${params.threads} \
    --minMAC ${params.regenie_min_mac} \
    --minINFO ${params.regenie_min_imputation_score} \
    --gz \
    $test \
    $bgen_sample \
    $range \
    $covariants \
    $deleteMissingData \
    $predictions \
    --out ${filename}
  """
}
