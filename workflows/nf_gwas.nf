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

//Optional condition-list file
if (!params.regenie_condition_list ) {
    condition_list_file = []
} else {
    condition_list_file = file(params.regenie_condition_list, checkIfExists: true)
}

if(params.outdir == null) {
    params.pubDir = "output/${params.project}"
} else {
    params.pubDir = params.outdir
}

include { INPUT_VALIDATION         } from './input_validation'
include { CONVERSION_CHUNKING      } from './conversion_chunking'
include { QUALITY_CONTROL          } from './quality_control'
include { PRUNING                  } from './pruning'
include { REGENIE_STEP1            } from './regenie_step1'
include { REGENIE_STEP2_GENE_TESTS } from './regenie_step2_gene_tests'
include { REGENIE_STEP2            } from './regenie_step2'
include { ANNOTATION               } from './annotation'
include { LIFT_OVER                } from './lift_over'
include { REPORTING                } from './reporting'
include { REPORTING_GENE_TESTS     } from './reporting_gene_tests'
include { FILTER_RESULTS           } from '../modules/local/filter_results' 
include { MERGE_RESULTS            } from '../modules/local/merge_results' 


workflow NF_GWAS {

    // TODO: Create sub-workflows for gene_based and classic gwas?

    /* executed for all modes */ 
    INPUT_VALIDATION()

    covariates_file_validated_log = INPUT_VALIDATION.out.covariates_file_validated_log
    covariates_file_validated  = INPUT_VALIDATION.out.covariates_file_validated
    phenotypes_file_validated = INPUT_VALIDATION.out.phenotypes_file_validated
    phenotypes_file_validated_log = INPUT_VALIDATION.out.phenotypes_file_validated_log

    if (!run_gene_tests) {
        CONVERSION_CHUNKING (
            genotypes_association,
            genotypes_association_format
        )
        imputed_plink2_ch = CONVERSION_CHUNKING.out.imputed_plink2_ch
    } else {
        step2_gene_tests_ch = Channel.fromFilePairs(genotypes_association, size: 3)
    }

    regenie_step1_parsed_logs_ch = Channel.empty()
    regenie_step1_out_ch = Channel.of('/')

    /* executed for all modes */ 
    if (!skip_predictions) {
        QUALITY_CONTROL(genotypes_prediction)
        genotyped_final_ch = QUALITY_CONTROL.out.genotyped_filtered_files_ch

        if(params.prune_enabled) {
            PRUNING(QUALITY_CONTROL.out.genotyped_filtered_files_ch)
            genotyped_final_ch = PRUNING.out.genotyped_final_ch
        } 

        REGENIE_STEP1(
            genotyped_final_ch,
            QUALITY_CONTROL.out.genotyped_filtered_snplist_ch,
            QUALITY_CONTROL.out.genotyped_filtered_id_ch,
            phenotypes_file_validated,
            covariates_file_validated,
            condition_list_file
        )

        regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out_ch
        regenie_step1_parsed_logs_ch = REGENIE_STEP1.out.regenie_step1_parsed_logs_ch
  
    } 

    if (!run_gene_tests) {
        REGENIE_STEP2 (
            regenie_step1_out_ch,
            imputed_plink2_ch,
            genotypes_association_format,
            phenotypes_file_validated,
            covariates_file_validated,
            condition_list_file,
            run_interaction_tests
        )

        regenie_step2_out = REGENIE_STEP2.out.regenie_step2_out

        if (!run_interaction_tests) {
            ANNOTATION (
                regenie_step2_out,
                association_build  
            )
            regenie_step2_by_phenotype = ANNOTATION.out.regenie_step2_by_phenotype
        } else {
            regenie_step2_by_phenotype = regenie_step2_out
        }

    } else {
        REGENIE_STEP2_GENE_TESTS (
            regenie_step1_out_ch,
            step2_gene_tests_ch,
            genotypes_association_format,
            phenotypes_file_validated,
            covariates_file_validated,
            condition_list_file
        )
        regenie_step2_by_phenotype = REGENIE_STEP2_GENE_TESTS.out.regenie_step2_by_phenotype

    }

    /* executed for all modes */ 
    MERGE_RESULTS (
    regenie_step2_by_phenotype.groupTuple()
    )

   /* executed for all modes */ 
    LIFT_OVER (
        MERGE_RESULTS.out.results_merged_regenie_only,
        association_build
    )

    if (!run_gene_tests) {

        FILTER_RESULTS (
            MERGE_RESULTS.out.results_merged
        )

        REPORTING (
            MERGE_RESULTS.out.results_merged,
            FILTER_RESULTS.out.results_filtered,
            phenotypes_file_validated,
            phenotypes_file_validated_log,
            covariates_file_validated_log.collect().ifEmpty([]),
            regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
            REGENIE_STEP2.out.regenie_step2_parsed_logs,
            run_interaction_tests
        )

    } else {
        REPORTING_GENE_TESTS (
            MERGE_RESULTS.out.results_merged,
            phenotypes_file_validated,
            phenotypes_file_validated_log,
            covariates_file_validated_log.collect().ifEmpty([]),
            regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
            REGENIE_STEP2_GENE_TESTS.out.regenie_step2_parsed_logs
        )
    }

}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

