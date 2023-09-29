ANSI_RESET = "\u001B[0m"
ANSI_YELLOW = "\u001B[33m"

if(params.genotypes_imputed){
    genotypes_association = params.genotypes_imputed
    println ANSI_YELLOW + "WARN: Option genotypes_imputed is deprecated. Please use genotypes_association instead." + ANSI_RESET
} else {
    genotypes_association = params.genotypes_association
}

//check deprecated option
if(params.genotypes_imputed_format){
    genotypes_association_format = params.genotypes_imputed_format
    println ANSI_YELLOW + "WARN: Option genotypes_imputed_format is deprecated. Please use genotypes_association_format instead." + ANSI_RESET
} else {
    genotypes_association_format = params.genotypes_association_format
}

if(params.genotypes_array){
    genotypes_prediction = params.genotypes_array
    println ANSI_YELLOW +  "WARN: Option genotypes_array is deprecated. Please use genotypes_prediction instead." + ANSI_RESET
} else {
    genotypes_prediction = params.genotypes_prediction
}

if(params.genotypes_build){
    association_build = params.genotypes_build
    println ANSI_YELLOW +  "WARN: Option genotypes_build is deprecated. Please use association_build instead." + ANSI_RESET
} else {
    association_build = params.association_build
}

requiredParams = [
    'project', 'phenotypes_filename','phenotypes_columns', 'phenotypes_binary_trait',
    'regenie_test'
]

requiredParamsGeneTests = [
    'project', 'phenotypes_filename', 'phenotypes_columns', 'phenotypes_binary_trait',
    'regenie_gene_anno', 'regenie_gene_setlist','regenie_gene_masks'
]

run_gene_tests = params.regenie_run_gene_based_tests
for (param in requiredParams) {
    if (params[param] == null  && !run_gene_tests) {
        exit 1, "Parameter ${param} is required for single-variant testing."
    }
}

//check if all gene-based options are set
for (param in requiredParamsGeneTests) {
    if (params[param] == null && run_gene_tests) {
        exit 1, "Parameter ${param} is required for gene-based testing."
    }
}

//check if all interaction options are set
run_interaction_tests = params.regenie_run_interaction_tests
if(run_interaction_tests && (params["regenie_interaction"] == null && params["regenie_interaction_snp"] == null) ) {
    exit 1, "Parameter regenie_interaction or regenie_interaction_snp must be set."
}

if(!run_interaction_tests && (params["regenie_interaction"] != null || params["regenie_interaction_snp"] != null)){
    exit 1, "Interaction parameters are set but regenie_run_interaction_tests is set to false."
}

//check general parameters
if(params["genotypes_association"] == null && params["genotypes_imputed"] == null ) {
    exit 1, "Parameter genotypes_association is required."
}

if(params["genotypes_association_format"] == null && params["genotypes_imputed_format"] == null ) {
    exit 1, "Parameter genotypes_association_format is required."
}

skip_predictions = params.regenie_skip_predictions
if(params["genotypes_array"] == null && params["genotypes_prediction"] == null && !skip_predictions ) {
    exit 1, "Parameter genotypes_prediction is required."
}

if(params["covariates_filename"] != null && (params.covariates_columns.isEmpty() && params.covariates_cat_columns.isEmpty())) {
    println ANSI_YELLOW+  "WARN: Option covariates_filename is set but no specific covariate columns (params: covariates_columns, covariates_cat_columns) are specified." + ANSI_RESET
}

if(params["genotypes_build"] == null && params["association_build"] == null ) {
    exit 1, "Parameter association_build is required."
}

if(params.genotypes_association_chunk_size > 0 && genotypes_association_format != 'bgen' ) {
    exit 1, " Chunking is currently only available for association files in bgen format (param: genotypes_association_chunk_size)."
}

if (run_gene_tests) {

    if (params.regenie_write_bed_masks && params.regenie_gene_build_mask == 'sum'){
        exit 1, "Invalid config file. The 'write-mask' option does not work when building masks with 'sum'."
    }

    //Check association file format for gene-based tests
    if (genotypes_association_format != 'bed'){
        exit 1, "File format " + genotypes_association_format + " currently not supported for gene-based tests. Please use 'bed' input instead. "
     }
} else {
    //Check if tests exists
    if (params.regenie_test != 'additive' && params.regenie_test != 'recessive' && params.regenie_test != 'dominant'){
        exit 1, "Test ${params.regenie_test} not supported for single-variant testing."
    }

    //Check association file format
    if (genotypes_association_format != 'vcf' && genotypes_association_format != 'bgen'){
        exit 1, "File format " + genotypes_association_format + " not supported."
    }
}

if(params.outdir == "default" || params.outdir == null) {
    params.pubDir = "output/${params.project}"
} else {
    params.pubDir = params.outdir
}


include { SINGLE_VARIANT_TESTS } from './single_variant_tests'
include { GENE_BASED_TESTS     } from './gene_based_tests'


workflow NF_GWAS {

    imputed_files_ch = channel.fromPath(genotypes_association, checkIfExists: true)
    phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)

    covariates_file = []
    if(params.covariates_filename) {
        
        covariates_file = file(params.covariates_filename, checkIfExists: true)

    }

    genotyped_plink_ch = Channel.empty()
    if(!skip_predictions) {
        
        genotyped_plink_ch = Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true)

    }

    //Optional condition-list file
    condition_list_file = Channel.empty()
    if (params.regenie_condition_list) {
            condition_list_file = Channel.fromPath(params.regenie_condition_list)
    } 

    if (!run_gene_tests) {
   
        SINGLE_VARIANT_TESTS(
            imputed_files_ch,
            phenotypes_file,
            covariates_file,
            genotyped_plink_ch,
            association_build,
            genotypes_association_format,
            condition_list_file,
            skip_predictions,
            run_interaction_tests
        )

    } else {
        
        GENE_BASED_TESTS(
            imputed_files_ch,
            phenotypes_file,
            covariates_file,
            genotyped_plink_ch,
            genotypes_association,
            association_build,
            genotypes_association_format,
            condition_list_file,
            skip_predictions,
            run_interaction_tests
        )
    
    }
}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

