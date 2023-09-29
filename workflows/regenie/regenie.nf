include { REGENIE_STEP1 } from './regenie_step1'
include { REGENIE_STEP2 } from './regenie_step2'
include { REGENIE_STEP2_GENE_TESTS } from './regenie_step2_gene_tests'

workflow REGENIE {

    take: 
    genotyped_final_ch
    genotyped_filtered_snplist_ch
    genotyped_filtered_id_ch
    phenotypes_file_validated
    covariates_file_validated
    condition_list_file
    imputed_plink2_ch
    genotypes_association_format
    run_interaction_tests
    skip_interaction
    gene_tests

    main:
    regenie_step1_parsed_logs_ch = Channel.empty()
    regenie_step1_out_ch = Channel.of('/')
    if(!skip_interaction) {
        REGENIE_STEP1(
            genotyped_final_ch,
            genotyped_filtered_snplist_ch,
            genotyped_filtered_id_ch,
            phenotypes_file_validated,
            covariates_file_validated.collect().ifEmpty([]),
            condition_list_file.collect().ifEmpty([])
        )

    regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out_ch
    regenie_step1_parsed_logs_ch = REGENIE_STEP1.out.regenie_step1_parsed_logs_ch
    } 
    
    if(!gene_tests) {
        REGENIE_STEP2 (
                regenie_step1_out_ch,
                imputed_plink2_ch,
                genotypes_association_format,
                phenotypes_file_validated,
                covariates_file_validated.collect().ifEmpty([]),
                condition_list_file.collect().ifEmpty([]),
                run_interaction_tests
        )

        regenie_step2_out = REGENIE_STEP2.out.regenie_step2_out
        regenie_step2_parsed_logs = REGENIE_STEP2.out.regenie_step2_parsed_logs

    } else {
         REGENIE_STEP2_GENE_TESTS (
            regenie_step1_out_ch,
            imputed_plink2_ch,
            genotypes_association_format,
            phenotypes_file_validated,
            covariates_file_validated.collect().ifEmpty([]),
            condition_list_file.collect().ifEmpty([])
        )

        regenie_step2_out = REGENIE_STEP2_GENE_TESTS.out.regenie_step2_by_phenotype
        regenie_step2_parsed_logs =  REGENIE_STEP2_GENE_TESTS.out.regenie_step2_parsed_logs
    }
    emit: 
    regenie_step2_out
    regenie_step2_parsed_logs
}

