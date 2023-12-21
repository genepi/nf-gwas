process REGENIE_STEP2_RUN_GENE_TESTS {

    publishDir "${params.pubDir}/logs", mode: 'copy', pattern: '*.log'
    publishDir "${params.pubDir}/masks", mode: 'copy', pattern: '*masks*.{txt,snplist,bed,bim,fam}'

    input:
    path step1_out
    tuple val(filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file), val(range)
    val assoc_format
	path phenotypes_file
    path covariates_file
    path sample_file
    path regenie_gene_anno_file
    path regenie_gene_setlist_file
    path regenie_gene_masks_file
    path condition_list_file

    output:
    tuple val(filename), path("*regenie.gz"), emit: regenie_step2_out
    path "${filename}.log", emit: regenie_step2_out_log
    path "${filename}_masks*"

    script:
    def format = assoc_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = assoc_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file ? "--sample $sample_file" : ''
    def firthApprox = params.regenie_firth_approx ? "--approx" : ""
    def firth = params.regenie_firth ? "--firth $firthApprox" : ""
    def binaryTrait =  params.phenotypes_binary_trait ? "--bt $firth " : ""
    def covariants = covariates_file ? "--covarFile $covariates_file" : ''
    def quant_covariants = params.covariates_columns ? "--covarColList ${params.covariates_columns}" : ''
    def cat_covariants = params.covariates_cat_columns ? "--catCovarList ${params.covariates_cat_columns}" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""
    def refFirst = params.regenie_ref_first  ? "--ref-first" : ''
    def apply_rint = params.phenotypes_apply_rint ? "--apply-rint" : ''
    def geneTest = params.regenie_gene_test ? "--vc-tests ${params.regenie_gene_test}":''
    def aaf = params.regenie_gene_aaf ? "--aaf-bins ${params.regenie_gene_aaf}":''
    def maxAaf = params.regenie_gene_vc_max_aaf ? "--vc-maxAAF ${params.regenie_gene_vc_max_aaf}":''
    def vcMACThr = params.regenie_gene_vc_mac_thr ? "--vc-MACthr ${params.regenie_gene_vc_mac_thr}":''
    def buildMask = params.regenie_gene_build_mask ? "--build-mask ${params.regenie_gene_build_mask}":''
    def writeMasks = params.regenie_write_bed_masks  ? "--write-mask" : ''
    def joint = params.regenie_gene_joint ? "--joint ${params.regenie_gene_joint}":''
    def condition_list = params.regenie_condition_list ? "--condition-list $condition_list_file" : ''
    def step2_optional = params.regenie_step2_optional  ? "$params.regenie_step2_optional":'' 

    """
    regenie \
        --step 2 \
        $format ${filename}${extension} \
        --phenoFile ${phenotypes_file} \
        --phenoColList  ${params.phenotypes_columns} \
        --bsize ${params.regenie_bsize_step2} \
        --pred regenie_step1_out_pred.list \
        --anno-file ${regenie_gene_anno_file} \
        --set-list ${regenie_gene_setlist_file} \
        --mask-def ${regenie_gene_masks_file} \
        --threads ${task.cpus} \
        --gz \
        --check-burden-files \
        --write-mask-snplist \
        $writeMasks \
        $binaryTrait \
        $covariants \
        $quant_covariants \
        $cat_covariants \
        $condition_list \
        $predictions \
        $apply_rint \
        $geneTest \
        $bgen_sample \
        $aaf \
        $maxAaf \
        $vcMACThr \
        $buildMask \
        $joint \
        --out ${filename} \
        $step2_optional
    """
}
