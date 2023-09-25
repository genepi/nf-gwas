//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

include { REGENIE_STEP2_RUN        } from '../modules/local/regenie_step2_run' 
include { REGENIE_LOG_PARSER_STEP2 } from '../modules/local/regenie_log_parser_step2'  

workflow REGENIE_STEP2 {

    take: 
    regenie_step1_out_ch
    imputed_plink2_ch
    genotypes_association_format
    phenotypes_file_validated
    covariates_file_validated
    condition_list_file
    run_interaction_tests

    main:
    if (!params.regenie_sample_file) {
        sample_file = []
    } else {
        sample_file = file(params.regenie_sample_file, checkIfExists: true)
    }

    REGENIE_STEP2_RUN (
        regenie_step1_out_ch.collect(),
        imputed_plink2_ch,
        genotypes_association_format,
        phenotypes_file_validated,
        sample_file,
        covariates_file_validated,
        condition_list_file,
        run_interaction_tests
    )

    if (run_interaction_tests){
        REGENIE_STEP2_RUN.out.regenie_step2_out_interaction
            .transpose()
            .map { prefix, fl -> tuple(RegenieUtil.getPhenotype(prefix, fl), fl) }
            .set { regenie_step2_out }
        } else {
            regenie_step2_out = REGENIE_STEP2_RUN.out.regenie_step2_out
    }

    regenie_step2_out_log = REGENIE_STEP2_RUN.out.regenie_step2_out_log
    
    REGENIE_LOG_PARSER_STEP2 (
        regenie_step2_out_log.collect()
    )

    regenie_step2_parsed_logs = REGENIE_LOG_PARSER_STEP2.out.regenie_step2_parsed_logs
   
    emit: 
    regenie_step2_parsed_logs
    regenie_step2_out

}