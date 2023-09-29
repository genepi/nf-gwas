include { INPUT_VALIDATION     } from './input_validation'
include { IMPUTED_TO_PLINK2    } from '../modules/local/imputed_to_plink2' 
include { CHUNKING             } from './chunking'
include { QUALITY_CONTROL      } from './quality_control'
include { PRUNING              } from './pruning'
include { REGENIE              } from './regenie/regenie'
include { ANNOTATION           } from './annotation'
include { MERGE_RESULTS        } from '../modules/local/merge_results' 
include { LIFT_OVER            } from './lift_over'
include { FILTER_RESULTS       } from '../modules/local/filter_results' 
include { REPORTING            } from './reporting'


workflow SINGLE_VARIANT_TESTS {
    
    take:
    imputed_files_ch
    phenotypes_file
    covariates_file
    genotyped_plink_ch
    association_build
    genotypes_association_format
    condition_list_file
    skip_predictions
    run_interaction_tests
    
    main:
    
    INPUT_VALIDATION(
        phenotypes_file,
        covariates_file
    )

    covariates_file_validated_log = INPUT_VALIDATION.out.covariates_file_validated_log
    covariates_file_validated  = INPUT_VALIDATION.out.covariates_file_validated
    phenotypes_file_validated = INPUT_VALIDATION.out.phenotypes_file_validated
    phenotypes_file_validated_log = INPUT_VALIDATION.out.phenotypes_file_validated_log

    if (genotypes_association_format == "vcf"){

        IMPUTED_TO_PLINK2 (
            imputed_files_ch
        )

        imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2
    
    } else {

        CHUNKING (
            imputed_files_ch
        )
        imputed_plink2_ch = CHUNKING.out.imputed_plink2_ch
    }

    genotyped_final_ch = Channel.empty()
    genotyped_filtered_snplist_ch = Channel.empty()
    genotyped_filtered_id_ch = Channel.empty()
   
    if (!skip_predictions) {

        QUALITY_CONTROL(genotyped_plink_ch)
        genotyped_final_ch = QUALITY_CONTROL.out.genotyped_filtered_files_ch
        genotyped_filtered_snplist_ch = QUALITY_CONTROL.out.genotyped_filtered_snplist_ch
        genotyped_filtered_id_ch = QUALITY_CONTROL.out.genotyped_filtered_id_ch
        
        if(params.prune_enabled) {

            PRUNING(QUALITY_CONTROL.out.genotyped_filtered_files_ch)
            genotyped_final_ch = PRUNING.out.genotyped_final_ch

        } 
            
    }
       
    REGENIE (
        genotyped_final_ch,
        genotyped_filtered_snplist_ch,
        genotyped_filtered_id_ch,
        phenotypes_file_validated,
        covariates_file_validated,
        condition_list_file,
        imputed_plink2_ch,
        genotypes_association_format,
        run_interaction_tests,
        skip_predictions,
        false
    )

    regenie_step2_out = REGENIE.out.regenie_step2_out
    regenie_step2_parsed_logs = REGENIE.out.regenie_step2_parsed_logs
    //TODO return logs from step1
    regenie_step1_parsed_logs_ch = Channel.empty()

    if (!run_interaction_tests) {

        ANNOTATION (
            regenie_step2_out,
            association_build  
        )
        regenie_step2_by_phenotype = ANNOTATION.out.regenie_step2_by_phenotype

    } else {

        regenie_step2_by_phenotype = regenie_step2_out

    }
        
    MERGE_RESULTS (
        regenie_step2_by_phenotype.groupTuple()
    )

    LIFT_OVER (
        MERGE_RESULTS.out.results_merged_regenie_only,
        association_build
    )

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
        regenie_step2_parsed_logs,
        run_interaction_tests
    )
}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

