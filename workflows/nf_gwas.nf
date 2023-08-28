//check deprecated option
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
println ANSI_YELLOW+  "WARN: Option genotypes_array is deprecated. Please use genotypes_prediction instead." + ANSI_RESET
} else {
genotypes_prediction = params.genotypes_prediction
}

if(params.genotypes_build){
association_build = params.genotypes_build
println ANSI_YELLOW+  "WARN: Option genotypes_build is deprecated. Please use association_build instead." + ANSI_RESET
} else {
association_build = params.association_build
}

target_build = params.target_build

// nf-gwas supports three different modi. Single-variant (default), gene-based and interaction-testing
run_gene_tests = params.regenie_run_gene_based_tests
run_interaction_tests = params.regenie_run_interaction_tests

skip_predictions = params.regenie_skip_predictions

requiredParams = [
    'project', 'phenotypes_filename','phenotypes_columns', 'phenotypes_binary_trait',
    'regenie_test'
]

requiredParamsGeneTests = [
    'project', 'phenotypes_filename', 'phenotypes_columns', 'phenotypes_binary_trait',
    'regenie_gene_anno', 'regenie_gene_setlist','regenie_gene_masks'
]

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

if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

phenotypes_array = params.phenotypes_columns.trim().split(',')

r_functions_file = file("$baseDir/reports/functions.R",checkIfExists: true)
rmd_valdiation_logs_file = file("$baseDir/reports/child_validationlogs.Rmd",checkIfExists: true)

if(!params.phenotypes_apply_rint) {
    rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics.Rmd",checkIfExists: true)
} else {
    rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics_rint.Rmd",checkIfExists: true)
}

//Annotation files
genes_hg19 = file("$baseDir/genes/genes.hg19.v32.csv", checkIfExists: true)
genes_hg38 = file("$baseDir/genes/genes.hg38.v32.csv", checkIfExists: true)

//Optional rsids annotation file and _tbi file
rsids = params.rsids_filename
if (rsids != null) {
  rsids_file = file(rsids, checkIfExists: true)
  rsids_tbi_file = file(rsids+".tbi", checkIfExists: true)
} else {
  println ANSI_YELLOW+  "WARN: A large rsID file will be downloaded for annotation. Please specify in config to avoid download." + ANSI_RESET

}

//Phenotypes
phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)
phenotypes = Channel.from(phenotypes_array)

//Optional covariates file
if (!params.covariates_filename) {
    covariates_file = []
} else {
    covariates_file = file(params.covariates_filename, checkIfExists: true)
}

//Optional sample file
if (!params.regenie_sample_file) {
    sample_file = []
} else {
    sample_file = file(params.regenie_sample_file, checkIfExists: true)
}

if (!skip_predictions){
Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true).set {genotyped_plink_ch}
}

//Optional condition-list file
if (!params.regenie_condition_list ) {
    condition_list_file = []
} else {
    condition_list_file = file(params.regenie_condition_list, checkIfExists: true)
}

// Load required files for gene-based tests
if (run_gene_tests) {
    gwas_report_template = file("$baseDir/reports/gene_level_report_template.Rmd",checkIfExists: true)
    regenie_anno_file    = file(params.regenie_gene_anno, checkIfExists: true)
    regenie_setlist_file = file(params.regenie_gene_setlist, checkIfExists: true)
    regenie_masks_file   = file(params.regenie_gene_masks, checkIfExists: true)

     if (params.regenie_write_bed_masks && params.regenie_gene_build_mask == 'sum'){
          exit 1, "Invalid config file. The 'write-mask' option does not work when building masks with 'sum'."
      }

      //Check association file format for gene-based tests
      if (genotypes_association_format != 'bed'){
        exit 1, "File format " + genotypes_association_format + " currently not supported for gene-based tests. Please use 'bed' input instead. "
      }

} else {
    // load interaction report template
    if (run_interaction_tests) {
        gwas_report_template = file("$baseDir/reports/gwas_report_interaction_template.Rmd",checkIfExists: true)
    } else {
        gwas_report_template = file("$baseDir/reports/gwas_report_template.Rmd",checkIfExists: true)
    }
    //Check if tests exists
    if (params.regenie_test != 'additive' && params.regenie_test != 'recessive' && params.regenie_test != 'dominant'){
          exit 1, "Test ${params.regenie_test} not supported for single-variant testing."
      }

    //Check association file format
    if (genotypes_association_format != 'vcf' && genotypes_association_format != 'bgen'){
      exit 1, "File format " + genotypes_association_format + " not supported."
    }
}

include { VALIDATE_PHENOTYPES         } from '../modules/local/validate_phenotypes' addParams(outdir: "$outdir")
include { VALIDATE_COVARIATES         } from '../modules/local/validate_covariates' addParams(outdir: "$outdir")
include { IMPUTED_TO_PLINK2           } from '../modules/local/imputed_to_plink2' addParams(outdir: "$outdir")
include { CHUNK_ASSOCIATION_FILES     } from '../modules/local/chunk_association_files' addParams(outdir: "$outdir")
include { COMBINE_MANIFEST_FILES      } from '../modules/local/combine_manifest_files' addParams(outdir: "$outdir")
include { PRUNE_GENOTYPED             } from '../modules/local/prune_genotyped' addParams(outdir: "$outdir")
include { QC_FILTER_GENOTYPED         } from '../modules/local/qc_filter_genotyped' addParams(outdir: "$outdir")
include { REGENIE_STEP1               } from '../modules/local/regenie_step1' addParams(outdir: "$outdir")
include { REGENIE_STEP1_SPLIT         } from '../modules/local/regenie_step1_split' addParams(outdir: "$outdir")
include { REGENIE_STEP1_MERGE_CHUNKS  } from '../modules/local/regenie_step1_merge_chunks' addParams(outdir: "$outdir")
include { REGENIE_STEP1_RUN_CHUNK     } from '../modules/local/regenie_step1_run_chunk' addParams(outdir: "$outdir")
include { REGENIE_LOG_PARSER_STEP1    } from '../modules/local/regenie_log_parser_step1'  addParams(outdir: "$outdir")
include { REGENIE_STEP2               } from '../modules/local/regenie_step2' addParams(outdir: "$outdir")
include { REGENIE_STEP2_GENE_TESTS    } from '../modules/local/regenie_step2_gene_tests' addParams(outdir: "$outdir")
include { REGENIE_LOG_PARSER_STEP2    } from '../modules/local/regenie_log_parser_step2'  addParams(outdir: "$outdir")
include { FILTER_RESULTS              } from '../modules/local/filter_results' addParams(outdir: "$outdir")
include { MERGE_RESULTS               } from '../modules/local/merge_results'  addParams(outdir: "$outdir")
include { ANNOTATE_RESULTS            } from '../modules/local/annotate_results'  addParams(outdir: "$outdir")
include { REPORT                      } from '../modules/local/report'  addParams(outdir: "$outdir")
include { REPORT_GENE_BASED_TESTS     } from '../modules/local/report_gene_based_tests'  addParams(outdir: "$outdir")
include { REPORT_INDEX                } from '../modules/local/report_index'  addParams(outdir: "$outdir")
include { DOWNLOAD_RSIDS              } from '../modules/local/download_rsids.nf'  addParams(outdir: "$outdir")
include { LIFTOVER_RESULTS            } from '../modules/local/liftover_results.nf'  addParams(outdir: "$outdir")



workflow NF_GWAS {

    VALIDATE_PHENOTYPES (
        phenotypes_file
    )

    covariates_file_validated_log = Channel.empty()
    if(params.covariates_filename) {
        VALIDATE_COVARIATES (
          covariates_file
        )

        covariates_file_validated = VALIDATE_COVARIATES.out.covariates_file_validated
        covariates_file_validated_log = VALIDATE_COVARIATES.out.covariates_file_validated_log

   } else {

        // set covariates_file to default value
        covariates_file_validated = covariates_file

   }

    //single-variant tests: convert vcf files to plink2 format (not bgen!)
    if (!run_gene_tests) {

      if (genotypes_association_format == "vcf"){

          imputed_files =  channel.fromPath(genotypes_association, checkIfExists: true)

          IMPUTED_TO_PLINK2 (
              imputed_files
          )

          imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2


      } else {
          chunk_size = params.genotypes_association_chunk_size
          strategy = params.genotypes_association_chunk_strategy

              if(chunk_size == 0) {

              //no conversion and chunking needed, set input to imputed_plink2_ch channel
              // -1 denotes that no range is applied
              channel.fromPath(genotypes_association)
              .map { tuple(it.baseName, it, [], [], -1) }
              .set {imputed_plink2_ch}

              } else {
                // chunking expects that a bgi file is available
                 Channel.fromPath(genotypes_association)
                .map {it -> tuple(it.baseName, it,file(it+".bgi", checkIfExists: true)) }
                .set {bgen_filepair}

                CHUNK_ASSOCIATION_FILES(bgen_filepair, chunk_size, strategy)
                COMBINE_MANIFEST_FILES(CHUNK_ASSOCIATION_FILES.out.chunks.collect())

                COMBINE_MANIFEST_FILES.out.combined_manifest
                .splitCsv(header:true, sep:',', quote: '\"')
                .map(row -> tuple(file(row["FILENAME"]).baseName,file(row["FILENAME"]),[],[],row["CONTIG"]+":" + row["START"] + "-" + row["END"]))
                .combine(bgen_filepair, by: 0)
                .map(row -> tuple(row[0], file(row[5]),file(row[6]),[],row[4]))
                .set {imputed_plink2_ch}

      }

      }

    //gene-based tests
    } else {

      if (genotypes_association_format == 'bed') {

        Channel.fromFilePairs(genotypes_association, size:3)
        .map { tuple(it[1][0].baseName, it[1][0], it[1][1], it[1][2]) }
        .set {step2_gene_tests_ch}

      }

    }

    regenie_step1_parsed_logs_ch = Channel.empty()

    if (!skip_predictions){

      QC_FILTER_GENOTYPED (
          genotyped_plink_ch
      )

      if(params.prune_enabled) {

          PRUNE_GENOTYPED (
              QC_FILTER_GENOTYPED.out.genotyped_filtered_files_ch
          )

          genotyped_final_ch = PRUNE_GENOTYPED.out.genotypes_pruned_ch

        } else {
            //no pruning applied, set QCed directly to genotyped_final_ch
            genotyped_final_ch = QC_FILTER_GENOTYPED.out.genotyped_filtered_files_ch
        }

        if (params.genotypes_prediction_chunks > 0){

          REGENIE_STEP1_SPLIT (
              genotyped_final_ch,
              QC_FILTER_GENOTYPED.out.genotyped_filtered_snplist_ch,
              QC_FILTER_GENOTYPED.out.genotyped_filtered_id_ch,
              VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
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
          for (int i = 1; i <= phenotypes_array.length; i++){
            phenotypesIndex["Y" + i] = phenotypes_array[i-1]
          }

          // Group chunk files per phenotype to parallelize merging
          REGENIE_STEP1_RUN_CHUNK.out.regenie_step1_out
            .flatMap()
            .map(
              it -> tuple(phenotypesIndex[getPhenotypeByChunk("chunks_job", it)], it)
            )
            .groupTuple()
            .set {groupedChunks }

          REGENIE_STEP1_MERGE_CHUNKS (
              REGENIE_STEP1_SPLIT.out.master.collect(),
              genotyped_final_ch.collect(),
              groupedChunks,
              QC_FILTER_GENOTYPED.out.genotyped_filtered_snplist_ch.collect(),
              QC_FILTER_GENOTYPED.out.genotyped_filtered_id_ch.collect(),
              VALIDATE_PHENOTYPES.out.phenotypes_file_validated.collect(),
              covariates_file_validated.collect(),
              condition_list_file.collect()
          )

          // merge pred.list files from chunks and add it to output channel
          mergedPredList = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out_pred.collectFile()

          regenie_step1_out_ch = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out.concat(mergedPredList)
          regenie_step1_parsed_logs_ch = Channel.empty()

        } else {
          REGENIE_STEP1 (
              genotyped_final_ch,
              QC_FILTER_GENOTYPED.out.genotyped_filtered_snplist_ch,
              QC_FILTER_GENOTYPED.out.genotyped_filtered_id_ch,
              VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
              covariates_file_validated,
              condition_list_file
          )

          REGENIE_LOG_PARSER_STEP1 (
              REGENIE_STEP1.out.regenie_step1_out_log
          )

          regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out
          regenie_step1_parsed_logs_ch = REGENIE_LOG_PARSER_STEP1.out.regenie_step1_parsed_logs
        }

    } else {

        regenie_step1_out_ch = Channel.of('/')

    }

    if (run_gene_tests){

      REGENIE_STEP2_GENE_TESTS (
          regenie_step1_out_ch.collect(),
          step2_gene_tests_ch,
          genotypes_association_format,
          VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
          covariates_file_validated,
          regenie_anno_file,
          regenie_setlist_file,
          regenie_masks_file,
          condition_list_file
      )

      regenie_step2_log_ch = REGENIE_STEP2_GENE_TESTS.out.regenie_step2_out_log
      regenie_step2_out_ch = REGENIE_STEP2_GENE_TESTS.out.regenie_step2_out

      // for gene-based testing phenotypes are split into seperate files
      regenie_step2_out_ch
      .transpose()
      .map { prefix, fl -> tuple(getPhenotype(prefix, fl), fl) }
      .set { regenie_step2_by_phenotype }

    }  else if (run_interaction_tests){

        REGENIE_STEP2 (
          regenie_step1_out_ch.collect(),
          imputed_plink2_ch,
          genotypes_association_format,
          VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
          sample_file,
          covariates_file_validated,
          condition_list_file,
          run_interaction_tests
        )

      regenie_step2_log_ch = REGENIE_STEP2.out.regenie_step2_out_log
      regenie_step2_out_ch = REGENIE_STEP2.out.regenie_step2_out_interaction

      // for gene-based testing phenotypes are split into seperate files
      regenie_step2_out_ch
      .transpose()
      .map { prefix, fl -> tuple(getPhenotype(prefix, fl), fl) }
      .set { regenie_step2_by_phenotype }

    }  else {
        
        REGENIE_STEP2 (
          regenie_step1_out_ch.collect(),
          imputed_plink2_ch,
          genotypes_association_format,
          VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
          sample_file,
          covariates_file_validated,
          condition_list_file,
          run_interaction_tests
        )

        regenie_step2_log_ch = REGENIE_STEP2.out.regenie_step2_out_log
        regenie_step2_out_ch = REGENIE_STEP2.out.regenie_step2_out

        if(rsids == null) {
          DOWNLOAD_RSIDS(association_build)
          annotation_files =  DOWNLOAD_RSIDS.out.rsids_ch
        } else {
          annotation_files = tuple(rsids_file, rsids_tbi_file)
       }

        ANNOTATE_RESULTS (
          regenie_step2_out_ch,
          genes_hg19,
          genes_hg38,
          annotation_files,
          association_build
        )

      // for default step2 annotation are splitting into seperate phenotypes files after annotation
        ANNOTATE_RESULTS.out.annotated_ch
        .transpose()
      .map { prefix, fl -> tuple(getPhenotype(prefix, fl), fl) }
        .set { regenie_step2_by_phenotype }

    } // end else

    
    REGENIE_LOG_PARSER_STEP2 (
       regenie_step2_log_ch.collect()
    )
 
    MERGE_RESULTS (
    regenie_step2_by_phenotype.groupTuple()
    )

    if(target_build != null && !association_build.equals(target_build)) {

      chain_file = file("$baseDir/files/chains/${association_build}To${target_build}.over.chain.gz", checkIfExists: true)

      LIFTOVER_RESULTS (
      MERGE_RESULTS.out.results_merged_regenie_only,
      chain_file,
      target_build
      )

    }


  if (!run_gene_tests) {

    FILTER_RESULTS (
        MERGE_RESULTS.out.results_merged
    )

    //TODO: change with list coming from new interactive manhattan plot
    //combined merge results and annotated filtered results by phenotype (index 0)

    merged_results_and_annotated_filtered =  MERGE_RESULTS.out.results_merged
                                                .combine( FILTER_RESULTS.out.results_filtered, by: 0)

    REPORT (
    merged_results_and_annotated_filtered,
    VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
    gwas_report_template,
    r_functions_file,
    rmd_pheno_stats_file,
    rmd_valdiation_logs_file,
    VALIDATE_PHENOTYPES.out.phenotypes_file_validated_log,
    covariates_file_validated_log.collect().ifEmpty([]),
    regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
    REGENIE_LOG_PARSER_STEP2.out.regenie_step2_parsed_logs
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

} else {

      REPORT_GENE_BASED_TESTS (
      MERGE_RESULTS.out.results_merged,
      VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
      gwas_report_template,
      r_functions_file,
      regenie_masks_file,
      rmd_pheno_stats_file,
      rmd_valdiation_logs_file,
      VALIDATE_PHENOTYPES.out.phenotypes_file_validated_log,
      covariates_file_validated_log.collect().ifEmpty([]),
      regenie_step1_parsed_logs_ch.collect().ifEmpty([]),
      REGENIE_LOG_PARSER_STEP2.out.regenie_step2_parsed_logs
      )

 }

}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

// extract phenotype name from regenie output file
def getPhenotype(prefix, file ) {
  return file.baseName.replaceAll(prefix, '').split('_',2)[1].replaceAll('.regenie', '')
}

// extract phenotype name from regenie step1 chunk file
def getPhenotypeByChunk(prefix, file ) {
  return file.baseName.replaceAll(prefix, '').split('_',3)[2].replaceAll('.regenie', '')
}
