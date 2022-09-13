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


requiredParams = [
    'project', 'phenotypes_filename','phenotypes_columns', 'phenotypes_binary_trait',
    'genotypes_association_format', 'genotypes_prediction','genotypes_association', 'genotypes_build',
    'regenie_test'
]

requiredParamsGeneTests = [
    'project', 'phenotypes_filename', 'phenotypes_columns', 'phenotypes_binary_trait',
    'genotypes_association_format', 'genotypes_prediction','genotypes_association',
    'regenie_gene_anno', 'regenie_gene_setlist','regenie_gene_masks'
]

for (param in requiredParams) {
    if (params[param] == null && param == null) {
      exit 1, "Parameter ${param} is required for single-variant testing."
    }
}

for (param in requiredParamsGeneTests) {
    if (params[param] == null && param == null) {
      exit 1, "Parameter ${param} is required for gene-based testing."
    }
}

if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

phenotypes_array = params.phenotypes_columns.trim().split(',')

covariates_array= []
if(!params.covariates_columns.isEmpty()){
    covariates_array = params.covariates_columns.trim().split(',')
}

r_functions_file = file("$baseDir/reports/functions.R",checkIfExists: true)
rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics.Rmd",checkIfExists: true)
rmd_valdiation_logs_file = file("$baseDir/reports/child_validationlogs.Rmd",checkIfExists: true)

//Annotation files
genes_hg19 = file("$baseDir/genes/genes.GRCh37.sorted.bed", checkIfExists: true)
genes_hg38 = file("$baseDir/genes/genes.GRCh38.sorted.bed", checkIfExists: true)

//Phenotypes
phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)
phenotypes = Channel.from(phenotypes_array)

run_gene_tests = params.regenie_run_gene_based_tests

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

Channel.fromFilePairs(genotypes_prediction, size: 3).set {genotyped_plink_ch}


// set to empty array since it's required for report
regenie_masks_file = []

// Load required files for gene-based tests
if (run_gene_tests) {
    gwas_report_template     = file("$baseDir/reports/gene_level_report_template.Rmd",checkIfExists: true)
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
    gwas_report_template = file("$baseDir/reports/gwas_report_template.Rmd",checkIfExists: true)
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
include { PRUNE_GENOTYPED             } from '../modules/local/prune_genotyped' addParams(outdir: "$outdir")
include { QC_FILTER_GENOTYPED         } from '../modules/local/qc_filter_genotyped' addParams(outdir: "$outdir")
include { REGENIE_STEP1               } from '../modules/local/regenie_step1' addParams(outdir: "$outdir")
include { REGENIE_LOG_PARSER_STEP1    } from '../modules/local/regenie_log_parser_step1'  addParams(outdir: "$outdir")
include { REGENIE_STEP2               } from '../modules/local/regenie_step2' addParams(outdir: "$outdir")
include { REGENIE_STEP2_GENE_TESTS    } from '../modules/local/regenie_step2_gene_tests' addParams(outdir: "$outdir")
include { REGENIE_LOG_PARSER_STEP2    } from '../modules/local/regenie_log_parser_step2'  addParams(outdir: "$outdir")
include { FILTER_RESULTS              } from '../modules/local/filter_results'
include { MERGE_RESULTS_FILTERED      } from '../modules/local/merge_results_filtered'  addParams(outdir: "$outdir")
include { MERGE_RESULTS               } from '../modules/local/merge_results'  addParams(outdir: "$outdir")
include { ANNOTATE_FILTERED           } from '../modules/local/annotate_filtered'  addParams(outdir: "$outdir")
include { REPORT                      } from '../modules/local/report'  addParams(outdir: "$outdir")

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
          //no conversion needed (already BGEN), set input to imputed_plink2_ch channel
          channel.fromPath(genotypes_association)
          .map { tuple(it.baseName, it, [], []) }
          .set {imputed_plink2_ch}
      }

    //gene-based tests
    } else {

      if (genotypes_association_format == 'bed') {

        Channel.fromFilePairs(genotypes_association, size: 3).set {step2_gene_tests_ch}

      }

    }

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

    regenie_step1_parsed_logs_ch = Channel.empty()
    if (!params.regenie_skip_predictions){

        REGENIE_STEP1 (
            genotyped_final_ch,
            QC_FILTER_GENOTYPED.out.genotyped_filtered_snplist_ch,
            QC_FILTER_GENOTYPED.out.genotyped_filtered_id_ch,
            VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
            covariates_file_validated
        )

        REGENIE_LOG_PARSER_STEP1 (
            REGENIE_STEP1.out.regenie_step1_out_log
        )

        regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out
        regenie_step1_parsed_logs_ch = REGENIE_LOG_PARSER_STEP1.out.regenie_step1_parsed_logs

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
          regenie_masks_file
      )

      regenie_step2_log_ch = REGENIE_STEP2_GENE_TESTS.out.regenie_step2_out_log
      regenie_step2_out_ch = REGENIE_STEP2_GENE_TESTS.out.regenie_step2_out

    } else {

      REGENIE_STEP2 (
          regenie_step1_out_ch.collect(),
          imputed_plink2_ch,
          genotypes_association_format,
          VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
          sample_file,
          covariates_file_validated
      )

      regenie_step2_log_ch = REGENIE_STEP2.out.regenie_step2_out_log
      regenie_step2_out_ch = REGENIE_STEP2.out.regenie_step2_out

    }

    REGENIE_LOG_PARSER_STEP2 (
        regenie_step2_log_ch.collect()
    )

// regenie creates a file for each tested phenotype. Merge-steps require to group by phenotype.
regenie_step2_out_ch
  .transpose()
  .map { prefix, fl -> tuple(getPhenotype(prefix, fl), fl) }
  .set { regenie_step2_by_phenotype }


    FILTER_RESULTS (
        regenie_step2_by_phenotype
    )

    MERGE_RESULTS (
        regenie_step2_by_phenotype.groupTuple()
    )

    MERGE_RESULTS_FILTERED (
        FILTER_RESULTS.out.results_filtered.groupTuple()
    )

    ANNOTATE_FILTERED (
        MERGE_RESULTS_FILTERED.out.results_filtered_merged,
        genes_hg19,
        genes_hg38
    )

    //combined merge results and annotated filtered results by phenotype (index 0)
    merged_results_and_annotated_filtered =  MERGE_RESULTS.out.results_merged
                                                .combine( ANNOTATE_FILTERED.out.annotated_ch, by: 0)

    REPORT (
        merged_results_and_annotated_filtered,
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

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

// extract phenotype name from regenie output file
def getPhenotype(prefix, file ) {
    return file.baseName.replaceAll(prefix + "_", '').replaceAll('.regenie', '')
}
