process REGENIE_STEP2 {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.log'
  stageInMode 'copy'

  tag "${plink2_pgen_file.simpleName}"

  input:
	  path step1_out
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file)
    path phenotypes_file
    path sample_file
    path covariates_file

  output:
    tuple val(filename), path("*regenie.gz"), emit: regenie_step2_out
    path "${filename}.log", emit: regenie_step2_out_log

  script:
    def format = params.genotypes_imputed_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = params.genotypes_imputed_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file ? "--sample $sample_file" : ''
    def test = "--test $params.regenie_test"
    def firthApprox = params.regenie_firth_approx ? "--approx" : ""
    def firth = params.regenie_firth ? "--firth $firthApprox" : ""
    def binaryTrait =  params.phenotypes_binary_trait ? "--bt $firth " : ""
    def range = params.regenie_range != '' ? "--range $params.regenie_range" : ''
    def covariants = covariates_file ? "--covarFile $covariates_file --covarColList ${params.covariates_columns}" : ''
    def deleteMissingData = params.phenotypes_delete_missings  ? "--strict" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""
    def refFirst = params.regenie_ref_first  ? "--ref-first" : ''

  """

  # Back up the file
  mv regenie_step1_out_pred.list regenie_step1_out_pred.list.bak

  # Update the file paths to source local files
  awk '{n=split(\$NF,a,"/"); print \$1, a[n]}'  regenie_step1_out_pred.list.bak > regenie_step1_out_pred.list

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
    $deleteMissingData \
    $predictions \
    $refFirst \
    --out ${filename}
  """
}
