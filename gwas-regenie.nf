nextflow.enable.dsl=2

requiredParams = [
    params.project, params.genotypes_typed,
    params.genotypes_imputed, params.genotypes_build,
    params.genotypes_imputed_format, params.phenotypes_filename,
    params.phenotypes_columns, params.phenotypes_binary_trait,
    params.regenie_test
]

for (param in requiredParams) {
    if (param == null) {
      exit 1, "Please specify all required parameters."
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

gwas_report_template = file("$baseDir/reports/gwas_report_template.Rmd",checkIfExists: true)

//JBang scripts
regenie_log_parser  = file("$baseDir/bin/RegenieLogParser.java", checkIfExists: true)
regenie_filter = file("$baseDir/bin/RegenieFilter.java", checkIfExists: true)

//Annotation files
genes_hg19 = file("$baseDir/genes/genes.hg19.sorted.bed", checkIfExists: true)
genes_hg38 = file("$baseDir/genes/genes.hg38.sorted.bed", checkIfExists: true)

//Phenotypes
phenotype_file = file(params.phenotypes_filename, checkIfExists: true)
phenotypes = Channel.from(phenotypes_array)

//Covariates
covariate_file = file(params.covariates_filename)
if (params.covariates_filename != 'NO_COV_FILE' && !covariate_file.exists()){
  exit 1, "Covariate file ${params.covariates_filename} not found."
}

//Optional sample file
sample_file = file(params.regenie_sample_file)
if (params.regenie_sample_file != 'NO_SAMPLE_FILE' && !sample_file.exists()){
  exit 1, "Sample file ${params.regenie_sample_file} not found."
}

//Check specified test
if (params.regenie_test != 'additive' && params.regenie_test != 'recessive' && params.regenie_test != 'dominant'){
  exit 1, "Test ${params.regenie_test} not supported."
}

//Check imputed file format
if (params.genotypes_imputed_format != 'vcf' && params.genotypes_imputed_format != 'bgen'){
  exit 1, "File format ${params.genotypes_imputed_format} not supported."
}

//Array genotypes
Channel.fromFilePairs("${params.genotypes_typed}", size: 3).set {genotyped_plink_ch}

include { CACHE_JBANG_SCRIPTS      } from './modules/local/cache_jbang_scripts'
include { VCF_TO_PLINK2            } from './modules/local/vcf_to_plink2' addParams(outdir: "$outdir")
include { SNP_PRUNING              } from './modules/local/snp_pruning'
include { QUALITY_CONTROL_FILTERS  } from './modules/local/quality_control_filters'
include { REGENIE_STEP1            } from './modules/local/regenie_step1'
include { PARSE_REGENIE_LOG_STEP1  } from './modules/local/parse_regenie_log_step1'  addParams(outdir: "$outdir")
include { REGENIE_STEP2            } from './modules/local/regenie_step2'
include { PARSE_REGENIE_LOG_STEP2  } from './modules/local/parse_regenie_log_step2'  addParams(outdir: "$outdir")
include { FILTER_RESULTS           } from './modules/local/filter_results'
include { MERGE_RESULTS_FILTERED   } from './modules/local/merge_results_filtered'  addParams(outdir: "$outdir")
include { MERGE_RESULTS_UNFILTERED } from './modules/local/merge_results_unfiltered'  addParams(outdir: "$outdir")
include { GWAS_TOPHITS             } from './modules/local/gwas_tophits'
include { ANNOTATE_TOPHITS         } from './modules/local/annotate_tophits'  addParams(outdir: "$outdir")
include { GWAS_REPORT              } from './modules/local/gwas_report'  addParams(outdir: "$outdir")

workflow {

    CACHE_JBANG_SCRIPTS (
        regenie_log_parser,
        regenie_filter
    )

    //convert vcf files to plink2 format (not bgen!)
    if (params.genotypes_imputed_format == "vcf"){
        imputed_data =  channel.fromPath("${params.genotypes_imputed}")

        VCF_TO_PLINK2 (
            imputed_data
        )

        imputed_plink_ch = VCF_TO_PLINK2.out.imputed_plink

    }  else {

        //nothing to do, forward imputed into same channel
        channel.fromPath("${params.genotypes_imputed}")
        .map { tuple(it.baseName, it, file('dummy_a'), file('dummy_b')) }
        .set {imputed_plink_ch}
    }


    if(params.prune_enabled) {

        SNP_PRUNING (
            genotyped_plink_ch
        )

        genotyped_plink_pruned_ch = SNP_PRUNING.out.genotypes_pruned

      } else {
          //no pruning, forward genotyped into same channel
          Channel.fromFilePairs("${params.genotypes_typed}", size: 3, flat: true).set {genotyped_plink_pruned_ch}
      }

    QUALITY_CONTROL_FILTERS (
        genotyped_plink_pruned_ch
    )

        if (!params.regenie_skip_predictions){

            REGENIE_STEP1 (
                genotyped_plink_pruned_ch,
                phenotype_file,
                QUALITY_CONTROL_FILTERS.out.genotyped_qc,
                covariate_file
            )

            PARSE_REGENIE_LOG_STEP1 (
                REGENIE_STEP1.out.fit_bin_log_ch.collect(),
                CACHE_JBANG_SCRIPTS.out.regenie_log_parser_jar
            )

            fit_bin_out_ch = REGENIE_STEP1.out.fit_bin_out_ch
            logs_step1_ch = PARSE_REGENIE_LOG_STEP1.out.logs_step1_ch

          } else {

              fit_bin_out_ch = Channel.of('/')

              logs_step1_ch = Channel.fromPath("NO_LOG")

            }

    REGENIE_STEP2 (
        imputed_plink_ch,
        phenotype_file,
        sample_file,
        fit_bin_out_ch.collect(),
        covariate_file
    )

    PARSE_REGENIE_LOG_STEP2 (
        REGENIE_STEP2.out.gwas_results_ch2.collect(),
        CACHE_JBANG_SCRIPTS.out.regenie_log_parser_jar
    )

    FILTER_RESULTS (
        REGENIE_STEP2.out.gwas_results_ch.flatten(),
        CACHE_JBANG_SCRIPTS.out.regenie_filter_jar
    )

    MERGE_RESULTS_FILTERED (
        FILTER_RESULTS.out.gwas_results_filtered_ch.collect(),
        phenotypes
    )

    MERGE_RESULTS_UNFILTERED (
        FILTER_RESULTS.out.gwas_results_unfiltered_ch.collect(),
        phenotypes
    )

    GWAS_TOPHITS (
        MERGE_RESULTS_FILTERED.out.regenie_merged_filtered_ch
    )

    ANNOTATE_TOPHITS (
        GWAS_TOPHITS.out.tophits_ch,
        genes_hg19,
        genes_hg38
    )

    GWAS_REPORT (
        MERGE_RESULTS_UNFILTERED.out.regenie_merged_unfiltered_ch,
        phenotype_file,
        gwas_report_template,
        logs_step1_ch.collect(),
        PARSE_REGENIE_LOG_STEP2.out.logs_step2_ch
    )
}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
