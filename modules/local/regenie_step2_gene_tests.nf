process REGENIE_STEP2_GENE_TESTS {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.log'

  input:
	  path step1_out
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)
    path id
    path phenotypes_file
    path covariates_file
    path regenie_gene_annot
    path regenie_gene_setlist
    path regenie_gene_masks

  output:
    tuple val(genotyped_plink_filename), path("*regenie.gz"), emit: regenie_step2_out
    path "${genotyped_plink_filename}.log", emit: regenie_step2_out_log

  script:
    def firthApprox = params.regenie_firth_approx ? "--approx" : ""
    def firth = params.regenie_firth ? "--firth $firthApprox" : ""
    def test = "--test $params.regenie_test"
    def binaryTrait =  params.phenotypes_binary_trait ? "--bt $firth " : ""
    def covariants = covariates_file.name != 'NO_COV_FILE' ? "--covarFile $covariates_file --covarColList ${params.covariates_columns}" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""
    def genetest = params.regenie_gene_test != 'NO_GENE_TEST' ? "--vc-tests ${params.regenie_gene_test}" : "--vc-tests skat"
    def aaf = "--aaf-bins ${params.regenie_gene_aaf}"
  """
  regenie \
    --step 2 \
    --bed ${genotyped_plink_filename} \
    --keep ${id} \
    --phenoFile ${phenotypes_file} \
    --phenoColList  ${params.phenotypes_columns} \
    --bsize ${params.regenie_bsize_step1} \
    --pred regenie_step1_out_pred.list \
    --threads ${task.cpus} \
    --anno-file ${regenie_gene_annot} \
    --set-list ${regenie_gene_setlist} \
    --mask-def ${regenie_gene_masks} \
    --gz \
    $aaf \
    --write-mask \
    $binaryTrait \
    $covariants \
    $predictions \
    $test \
    $genetest \
    --out ${genotyped_plink_filename}
  """
}
