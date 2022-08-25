process REGENIE_STEP2_GENE_TESTS {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.log'
    publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.txt'
      publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.snplist'

  input:
    path step1_out
    tuple val(plink_filename), path(genotyped_plink_file)
	  path phenotypes_file
    path covariates_file
    path regenie_gene_anno_file
    path regenie_gene_setlist_file
    path regenie_gene_masks_file

  output:
    tuple val(plink_filename), path("*regenie.gz"), emit: regenie_step2_out
    path "${plink_filename}.log", emit: regenie_step2_out_log
    path "${plink_filename}_masks_report.txt"
    path "${plink_filename}_masks.snplist"

  script:
    def format = params.genotypes_imputed_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = params.genotypes_imputed_format == 'bgen' ? ".bgen" : ''
    def firthApprox = params.regenie_firth_approx ? "--approx" : ""
    def firth = params.regenie_firth ? "--firth $firthApprox" : ""
    def binaryTrait =  params.phenotypes_binary_trait ? "--bt $firth " : ""
    def covariants = covariates_file ? "--covarFile $covariates_file --covarColList ${params.covariates_columns}" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""
    def refFirst = params.regenie_ref_first  ? "--ref-first" : ''
    def geneTest = params.regenie_gene_test ? "--vc-tests ${params.regenie_gene_test}":''
    def aaf = params.regenie_gene_aaf ? "--aaf-bins ${params.regenie_gene_aaf}":''
    def maxAaf = params.regenie_gene_vc_max_aaf ? "--vc-maxAAF ${params.regenie_gene_vc_max_aaf}":''
    def vcMACThr = params.regenie_gene_vc_mac_thr ? "--vc-MACthr ${params.regenie_gene_vc_mac_thr}":''
    def buildMask = params.regenie_gene_build_mask ? "--build-mask ${params.regenie_gene_build_mask}":''
    def joint = params.regenie_gene_joint ? "--joint ${params.regenie_gene_joint}":''

  """
  regenie \
    --step 2 \
    --bed ${plink_filename}\
    --phenoFile ${phenotypes_file} \
    --phenoColList  ${params.phenotypes_columns} \
    --bsize ${params.regenie_bsize_step2} \
    --pred regenie_step1_out_pred.list \
    --anno-file ${regenie_gene_anno_file} \
    --set-list ${regenie_gene_setlist_file} \
    --mask-def ${regenie_gene_masks_file} \
    --threads ${task.cpus} \
    --gz \
    --write-mask \
    --check-burden-files \
    --write-mask-snplist \
    $binaryTrait \
    $covariants \
    $predictions \
    $geneTest \
    $aaf \
    $maxAaf \
    $vcMACThr \
    $buildMask \
    $joint \
    --out ${plink_filename}
  """
}
