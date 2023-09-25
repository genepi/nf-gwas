include { REGENIE_STEP1_RUN           } from '../modules/local/regenie_step1_run' 
include { REGENIE_STEP1_SPLIT         } from '../modules/local/regenie_step1_split'
include { REGENIE_STEP1_MERGE_CHUNKS  } from '../modules/local/regenie_step1_merge_chunks'
include { REGENIE_STEP1_RUN_CHUNK     } from '../modules/local/regenie_step1_run_chunk' 
include { REGENIE_LOG_PARSER_STEP1    } from '../modules/local/regenie_log_parser_step1' 

workflow REGENIE_STEP1 {

    take: 
    genotyped_final_ch
    genotyped_filtered_snplist_ch
    genotyped_filtered_id_ch
    phenotypes_file_validated
    covariates_file_validated
    condition_list_file
    main:
   
    if (params.genotypes_prediction_chunks > 0){

        REGENIE_STEP1_SPLIT (
        genotyped_final_ch,
        genotyped_filtered_snplist_ch,
        genotyped_filtered_id_ch,
        phenotypes_file_validated,
        covariates_file_validated,
        condition_list_file
        )

        chunkNumber = 0;
        Channel.of(1..params.genotypes_prediction_chunks)
            .combine(REGENIE_STEP1_SPLIT.out.chunks)
            .set { chunks_ch }

        REGENIE_STEP1_RUN_CHUNK (
            chunks_ch
         )

        // build map from Y_n to phenotype name
        def phenotypesIndex = [:]
        phenotypes_array = params.phenotypes_columns.trim().split(',')
        for (int i = 1; i <= phenotypes_array.length; i++){
            phenotypesIndex["Y" + i] = phenotypes_array[i-1]
        }

          // Group chunk files per phenotype to parallelize merging
        REGENIE_STEP1_RUN_CHUNK.out.regenie_step1_out
            .flatMap()
            .map(
                it -> tuple(phenotypesIndex[RegenieUtil.getPhenotypeByChunk("chunks_job", it)], it)
                )
            .groupTuple()
            .set {groupedChunks }

        REGENIE_STEP1_MERGE_CHUNKS (
            REGENIE_STEP1_SPLIT.out.master.collect(),
            genotyped_final_ch.collect(),
            groupedChunks,
            genotyped_filtered_snplist_ch.collect(),
            genotyped_filtered_id_ch.collect(),
            phenotypes_file_validated.collect(),
            covariates_file_validated.collect(),
            condition_list_file.collect()
        )

        // merge pred.list files from chunks and add it to output channel
        mergedPredList = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out_pred.collectFile()
        regenie_step1_out_ch = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out.concat(mergedPredList)
        regenie_step1_parsed_logs_ch = Channel.empty()

    } else {
        REGENIE_STEP1_RUN (
            genotyped_final_ch,
            genotyped_filtered_snplist_ch,
            genotyped_filtered_id_ch,
            phenotypes_file_validated,
            covariates_file_validated,
            condition_list_file
        )

        REGENIE_LOG_PARSER_STEP1 (
            REGENIE_STEP1_RUN.out.regenie_step1_out_log
        )

        regenie_step1_out_ch = REGENIE_STEP1_RUN.out.regenie_step1_out
        regenie_step1_parsed_logs_ch = REGENIE_LOG_PARSER_STEP1.out.regenie_step1_parsed_logs
        }

    emit: 
    regenie_step1_out_ch
    regenie_step1_parsed_logs_ch

}

