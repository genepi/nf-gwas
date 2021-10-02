process REGENIE_STEP2 {
	cpus "${params.threads}"
  tag "${filename}"
  //publishDir "$outdir/03_regenie_step2", mode: 'copy'

  input:
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file)
    path phenotype_file
    path sample_file
    path fit_bin_out
    path covariate_file

  output:
    path "gwas_results.*regenie.gz", emit: gwas_results_ch
    path "gwas_results.${filename}*log", emit: gwas_results_ch2
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
    --out gwas_results.${filename}
  """
}
