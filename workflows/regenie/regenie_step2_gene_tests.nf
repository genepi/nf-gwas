include { REGENIE_STEP2_RUN_GENE_TESTS } from '../../modules/local/regenie/regenie_step2_run_gene_tests' 
include { REGENIE_LOG_PARSER_STEP2 } from '../../modules/local/regenie/regenie_log_parser_step2'  

workflow REGENIE_STEP2_GENE_TESTS {

    take: 
    regenie_step1_out_ch
    step2_gene_tests_ch
    genotypes_association_format
    phenotypes_file_validated
    covariates_file_validated
    condition_list_file

    main:
    regenie_anno_file    = file(params.regenie_gene_anno, checkIfExists: true)
    regenie_setlist_file = file(params.regenie_gene_setlist, checkIfExists: true)
    regenie_masks_file   = file(params.regenie_gene_masks, checkIfExists: true)
    if (!params.regenie_sample_file) {
        sample_file = []
    } else {
        sample_file = file(params.regenie_sample_file, checkIfExists: true)
    }

    REGENIE_STEP2_RUN_GENE_TESTS (
        regenie_step1_out_ch.collect(),
        step2_gene_tests_ch,
        genotypes_association_format,
        phenotypes_file_validated,
        covariates_file_validated,
        sample_file,
        regenie_anno_file,
        regenie_setlist_file,
        regenie_masks_file,
        condition_list_file
    )

    // for gene-based testing phenotypes needs to be split into seperate files
    REGENIE_STEP2_RUN_GENE_TESTS.out.regenie_step2_out
        .transpose()
        .map { prefix, fl -> tuple(RegenieUtil.getPhenotype(prefix, fl), fl) }
        .set { regenie_step2_by_phenotype }

    regenie_step2_out_log = REGENIE_STEP2_RUN_GENE_TESTS.out.regenie_step2_out_log

    REGENIE_LOG_PARSER_STEP2 (
    regenie_step2_out_log.collect()
    )

    regenie_step2_parsed_logs = REGENIE_LOG_PARSER_STEP2.out.regenie_step2_parsed_logs
    
    emit: 
    regenie_step2_parsed_logs
    regenie_step2_by_phenotype
}


