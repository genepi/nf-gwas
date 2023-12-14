include { INPUT_VALIDATION     } from './input_validation'
include { IMPUTED_TO_PLINK2    } from '../modules/local/imputed_to_plink2' 
include { PRUNING              } from './pruning'
include { QUALITY_CONTROL      } from './quality_control'
include { REGENIE              } from './regenie/regenie'
include { MERGE_RESULTS        } from '../modules/local/merge_results' 
include { LIFT_OVER            } from './lift_over'
include { REPORTING_GENE_TESTS } from './reporting_gene_tests'



workflow GENE_BASED_TESTS {
    
    take:
    imputed_files_ch
    phenotypes_file
    covariates_file
    genotyped_plink_ch
    genotypes_association
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

        // imputed_plink2_ch = Channel.fromFilePairs(genotypes_association, size: 3)
        /*println "ERR: We do not support plink files anymore!!!"
        exit 1
        */
        // NB the chunking here is just needed to support bgen files
        imputed_files_ch
            .map { tuple(it.baseName, it, [], [], -1) }
            .set {imputed_plink2_ch}

        /* CHUNKING (
            imputed_files_ch
        )
        imputed_plink2_ch = CHUNKING.out.imputed_plink2_ch
        */

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
        covariates_file_validated.collect().ifEmpty([]),
        condition_list_file,
        imputed_plink2_ch,
        genotypes_association_format,
        run_interaction_tests,
        skip_predictions,
        true
    )

    regenie_step2_by_phenotype = REGENIE.out.regenie_step2_out
    regenie_step2_parsed_logs = REGENIE.out.regenie_step2_parsed_logs
    //TODO return logs from step1
    regenie_step1_parsed_logs_ch = Channel.empty()

    MERGE_RESULTS (
        regenie_step2_by_phenotype.groupTuple()
    )

    LIFT_OVER (
        MERGE_RESULTS.out.results_merged_regenie_only,
        association_build
    )

    REPORTING_GENE_TESTS (
            MERGE_RESULTS.out.results_merged,
            phenotypes_file_validated,
            phenotypes_file_validated_log,
            covariates_file_validated_log.collect().ifEmpty([]),
            regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
            regenie_step2_parsed_logs
    )
}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

