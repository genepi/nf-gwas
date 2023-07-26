process REGENIE_STEP2 {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.log'

  tag "${plink2_pgen_file.simpleName}"

  input:
	  path step1_out
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file)
    val assoc_format
    path phenotypes_file
    path sample_file
    path covariates_file
    path condition_list_file

  output:
    tuple val(filename), path("*regenie.gz"), emit: regenie_step2_out
    path "${filename}.log", emit: regenie_step2_out_log

  script:
    def format = assoc_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = assoc_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file ? "--sample $sample_file" : ''
    def test = "--test $params.regenie_test"
    def firthApprox = params.regenie_firth_approx ? "--approx" : ""
    def firth = params.regenie_firth ? "--firth $firthApprox" : ""
    def binaryTrait =  params.phenotypes_binary_trait ? "--bt $firth " : ""
    def range = params.regenie_range ? "--range $params.regenie_range" : ''
    def covariants = covariates_file ? "--covarFile $covariates_file" : ''
    def quant_covariants = params.covariates_columns ? "--covarColList ${params.covariates_columns}" : ''
    def cat_covariants = params.covariates_cat_columns ? "--catCovarList ${params.covariates_cat_columns}" : ''
    def deleteMissingData = params.phenotypes_delete_missings  ? "--strict" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""
    def refFirst = params.regenie_ref_first  ? "--ref-first" : ''
    def apply_rint = params.phenotypes_apply_rint ? "--apply-rint" : ''
    def interaction = params.regenie_interaction ? "--interaction $params.regenie_interaction" : ''
    def interaction_snp = params.regenie_interaction_snp ? "--interaction-snp $params.regenie_interaction_snp" : ''
    def rare_mac = params.regenie_rare_mac ? "--rare-mac $params.regenie_rare_mac" : ''
    def no_condtl = params.regenie_no_condtl ? "--no-condtl" : ''
    def force_condtl = params.regenie_force_condtl ? "--force-condtl" : ''
    def condition_list = params.regenie_condition_list ? "--condition-list $condition_list_file" : ''

  """
  regenie \
    --step 2 \
    $format ${filename}${extension} \
    --phenoFile ${phenotypes_file} \
    --phenoColList  ${params.phenotypes_columns} \
    --bsize ${params.regenie_bsize_step2} \
    --pred regenie_step1_out_pred.list \
    --threads ${task.cpus} \
    --minMAC ${params.regenie_min_mac} \
    --minINFO ${params.regenie_min_imputation_score} \
    --gz \
    $binaryTrait \
    $test \
    $bgen_sample \
    $range \
    $covariants \
    $quant_covariants \
    $cat_covariants \
    $condition_list \
    $deleteMissingData \
    $predictions \
    $refFirst \
    $apply_rint \
    $interaction \
    $interaction_snp \
    $rare_mac \
    $no_condtl \
    $force_condtl \
    --out ${filename}
  """
}
