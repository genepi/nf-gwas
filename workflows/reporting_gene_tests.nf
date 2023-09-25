include { REPORT_GENE_BASED_TESTS } from '../modules/local/report_gene_based_tests' 

workflow REPORTING_GENE_TESTS {

    take: 
    results_merged
    phenotypes_file_validated
    phenotypes_file_validated_log
    covariates_file_validated_log
    regenie_step1_parsed_logs_ch
    regenie_step2_parsed_logs
    
    main:
    gwas_report_template = file("$baseDir/reports/gene_level_report_template.Rmd",checkIfExists: true)
    r_functions_file = file("$baseDir/reports/functions.R",checkIfExists: true)
    rmd_valdiation_logs_file = file("$baseDir/reports/child_validationlogs.Rmd",checkIfExists: true) 

    if(!params.phenotypes_apply_rint) {
        rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics.Rmd",checkIfExists: true)
    } else {
        rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics_rint.Rmd",checkIfExists: true)   
    }
    regenie_masks_file = file(params.regenie_gene_masks, checkIfExists: true)

    REPORT_GENE_BASED_TESTS (
        results_merged,
        phenotypes_file_validated,
        gwas_report_template,
        r_functions_file,
        regenie_masks_file,
        rmd_pheno_stats_file,
        rmd_valdiation_logs_file,
        phenotypes_file_validated_log,
        covariates_file_validated_log.collect().ifEmpty([]),
        regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
        regenie_step2_parsed_logs
    )
}


