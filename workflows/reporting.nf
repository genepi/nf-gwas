//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

include { REPORT_INDEX } from '../modules/local/report_index' 
include { REPORT       } from '../modules/local/report'  

workflow REPORTING {

    take: 
    results_merged
    results_filtered
    phenotypes_file_validated
    phenotypes_file_validated_log
    covariates_file_validated_log
    regenie_step1_parsed_logs_ch
    regenie_step2_parsed_logs
    run_interaction_tests
    
    main:
    if (run_interaction_tests) {
        gwas_report_template = file("$baseDir/reports/gwas_report_interaction_template.Rmd",checkIfExists: true)
    } else {
        gwas_report_template = file("$baseDir/reports/gwas_report_template.Rmd",checkIfExists: true)
    }

    if(!params.phenotypes_apply_rint) {
        rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics.Rmd",checkIfExists: true)
    } else {
        rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics_rint.Rmd",checkIfExists: true)
    }

    r_functions_file = file("$baseDir/reports/functions.R",checkIfExists: true)
    rmd_valdiation_logs_file = file("$baseDir/reports/child_validationlogs.Rmd",checkIfExists: true)

    //TODO: change with list coming from new interactive manhattan plot
    //combined merge results and annotated filtered results by phenotype (index 0)
    merged_results_and_annotated_filtered =  results_merged
        .combine( results_filtered, by: 0)

    REPORT (
        merged_results_and_annotated_filtered,
        phenotypes_file_validated,
        gwas_report_template,
        r_functions_file,
        rmd_pheno_stats_file,
        rmd_valdiation_logs_file,
        phenotypes_file_validated_log,
        covariates_file_validated_log.collect().ifEmpty([]),
        regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
        regenie_step2_parsed_logs
    )

    //TODO: find better solution to avoid splitting in separate channels
    REPORT.out.phenotype_report
      .map{ row -> row[0] }
      .set { annotated_phenotypes_phenotypes }

    REPORT.out.phenotype_report
      .map{ row -> row[1] }
      .set { annotated_phenotypes_reports }

    REPORT.out.phenotype_report
      .map{ row -> row[2] }
      .set { annotated_phenotypes_manhattan }

    REPORT_INDEX (
      annotated_phenotypes_phenotypes.collect(),
      annotated_phenotypes_reports.collect(),
      annotated_phenotypes_manhattan.collect()
    )
 

}


