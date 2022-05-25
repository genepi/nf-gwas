process REGENIE_STEP2 {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.log'

  tag "${plink2_pgen_file.simpleName}"

  input:
	  path step1_out
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file)
    path phenotypes_file
    path sample_file
    path covariates_file

  output:
    tuple val(filename), path("*regenie.gz"), emit: regenie_gene_level_out
    path "${filename}.log", emit: regenie_gene_level_out_log

  script:
    def format = params.genotypes_imputed_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = params.genotypes_imputed_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file.name != 'NO_SAMPLE_FILE' ? "--sample $sample_file" : ''
    def test = "--test $params.regenie_test"
    def binaryTrait =  params.phenotypes_binary_trait ? "--bt $firth " : ""
    def covariants = covariates_file.name != 'NO_COV_FILE' ? "--covarFile $covariates_file --covarColList ${params.covariates_columns}" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""

  """
  regenie \
    --step 2 \
    $format ${filename}${extension} \
    --phenoFile ${phenotypes_file} \
    --phenoColList  ${params.phenotypes_columns} \
    --bsize ${params.regenie_bsize_step2} \
    --pred regenie_step1_out_pred.list \
    --threads ${task.cpus} \
    --anno-file example/example_3chr.annotations \
    --set-list example/example_3chr.setlist \
    --mask-def example/example_3chr.masks \
    --gz \
    --aaf-bins 0.1,0.05 \
    --write-mask \
    $binaryTrait \
    $test \
    $bgen_sample \
    $covariants \
    $predictions \
    --out ${filename}
  """
}
