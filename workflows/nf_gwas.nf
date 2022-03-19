
requiredParams = [
    'project', 'genotypes_array',
    'genotypes_imputed', 'genotypes_build',
    'genotypes_imputed_format', 'phenotypes_filename',
    'phenotypes_columns', 'phenotypes_binary_trait',
    'regenie_test'
]

for (param in requiredParams) {
    if (params[param] == null) {
      exit 1, "Parameter ${param} is required."
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
regenie_log_parser_java  = file("$baseDir/bin/RegenieLogParser.java", checkIfExists: true)
regenie_filter_java = file("$baseDir/bin/RegenieFilter.java", checkIfExists: true)
regenie_validate_input_java = file("$baseDir/bin/RegenieValidateInput.java", checkIfExists: true)

//Annotation files
genes_hg19 = file("$baseDir/genes/genes.GRCh37.sorted.bed", checkIfExists: true)
genes_hg38 = file("$baseDir/genes/genes.GRCh38.sorted.bed", checkIfExists: true)

//Phenotypes
phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)
phenotypes = Channel.from(phenotypes_array)

//Covariates
covariates_file = file(params.covariates_filename)
if (params.covariates_filename != 'NO_COV_FILE' && !covariates_file.exists()){
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
Channel.fromFilePairs("${params.genotypes_array}", size: 3).set {genotyped_plink_ch}

include { CACHE_JBANG_SCRIPTS         } from '../modules/local/cache_jbang_scripts'
include { VALIDATE_PHENOTYPES         } from '../modules/local/validate_phenotypes' addParams(outdir: "$outdir")
include { VALIDATE_COVARIATS          } from '../modules/local/validate_covariates' addParams(outdir: "$outdir")
include { IMPUTED_TO_PLINK2           } from '../modules/local/imputed_to_plink2' addParams(outdir: "$outdir")
include { PRUNE_GENOTYPED             } from '../modules/local/prune_genotyped' addParams(outdir: "$outdir")
include { QC_FILTER_GENOTYPED         } from '../modules/local/qc_filter_genotyped' addParams(outdir: "$outdir")
include { REGENIE_STEP1               } from '../modules/local/regenie_step1' addParams(outdir: "$outdir")
include { REGENIE_LOG_PARSER_STEP1    } from '../modules/local/regenie_log_parser_step1'  addParams(outdir: "$outdir")
include { REGENIE_STEP2               } from '../modules/local/regenie_step2' addParams(outdir: "$outdir")
include { REGENIE_LOG_PARSER_STEP2    } from '../modules/local/regenie_log_parser_step2'  addParams(outdir: "$outdir")
include { FILTER_RESULTS              } from '../modules/local/filter_results'
include { MERGE_RESULTS_FILTERED      } from '../modules/local/merge_results_filtered'  addParams(outdir: "$outdir")
include { MERGE_RESULTS               } from '../modules/local/merge_results'  addParams(outdir: "$outdir")
include { ANNOTATE_FILTERED           } from '../modules/local/annotate_filtered'  addParams(outdir: "$outdir")
include { REPORT                      } from '../modules/local/report'  addParams(outdir: "$outdir")

workflow NF_GWAS {

    CACHE_JBANG_SCRIPTS (
        regenie_log_parser_java,
        regenie_filter_java,
        regenie_validate_input_java
    )

    VALIDATE_PHENOTYPES (
        phenotypes_file,
        CACHE_JBANG_SCRIPTS.out.regenie_validate_input_jar
    )

    if(covariates_file.exists()) {
        VALIDATE_COVARIATS (
          covariates_file,
          CACHE_JBANG_SCRIPTS.out.regenie_validate_input_jar
        )

        covariates_file_validated = VALIDATE_COVARIATS.out.covariates_file_validated
        covariates_file_validated_log = VALIDATE_COVARIATS.out.covariates_file_validated_log

   } else {

     // set covariates_file to default value
     covariates_file_validated = covariates_file
     covariates_file_validated_log = Channel.fromPath("NO_COV_LOG")

   }

    //convert vcf files to plink2 format (not bgen!)
    if (params.genotypes_imputed_format == "vcf"){
        imputed_files =  channel.fromPath("${params.genotypes_imputed}", checkIfExists: true)

        IMPUTED_TO_PLINK2 (
            imputed_files
        )

        imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2

    }  else {

        //no conversion needed (already BGEN), set input to imputed_plink2_ch channel
        channel.fromPath("${params.genotypes_imputed}")
        .map { tuple(it.baseName, it, file('dummy_a'), file('dummy_b')) }
        .set {imputed_plink2_ch}
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

    if (!params.regenie_skip_predictions){

        REGENIE_STEP1 (
            genotyped_final_ch,
            QC_FILTER_GENOTYPED.out.genotyped_filtered_snplist_ch,
            QC_FILTER_GENOTYPED.out.genotyped_filtered_id_ch,
            VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
            covariates_file_validated
        )

        REGENIE_LOG_PARSER_STEP1 (
            REGENIE_STEP1.out.regenie_step1_out_log,
            CACHE_JBANG_SCRIPTS.out.regenie_log_parser_jar
        )

        regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out
        regenie_step1_parsed_logs_ch = REGENIE_LOG_PARSER_STEP1.out.regenie_step1_parsed_logs

    } else {

        regenie_step1_out_ch = Channel.of('/')

        regenie_step1_parsed_logs_ch = Channel.fromPath("NO_LOG")

    }

    REGENIE_STEP2 (
        regenie_step1_out_ch.collect(),
        imputed_plink2_ch,
        VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
        sample_file,
        covariates_file_validated
    )

    REGENIE_LOG_PARSER_STEP2 (
        REGENIE_STEP2.out.regenie_step2_out_log.collect(),
        CACHE_JBANG_SCRIPTS.out.regenie_log_parser_jar
    )

// regenie creates a file for each tested phenotype. Merge-steps require to group by phenotpe.
REGENIE_STEP2.out.regenie_step2_out
  .transpose()
  .map { prefix, file -> tuple(getPhenotype(prefix, file), file) }
  .set { regenie_step2_by_phenotype }


    FILTER_RESULTS (
        regenie_step2_by_phenotype,
        CACHE_JBANG_SCRIPTS.out.regenie_filter_jar
    )

    MERGE_RESULTS_FILTERED (
        FILTER_RESULTS.out.results_filtered.groupTuple()
    )

    MERGE_RESULTS (
        regenie_step2_by_phenotype.groupTuple()
    )

    ANNOTATE_FILTERED (
        MERGE_RESULTS_FILTERED.out.results_filtered_merged,
        genes_hg19,
        genes_hg38
    )

    //combined merge results and annotated filtered results by phenotype (index 0)
    merged_results_and_annotated_filtered =  MERGE_RESULTS.out.results_merged.combine(
      ANNOTATE_FILTERED.out.annotated_ch, by: 0
    )

    REPORT (
        merged_results_and_annotated_filtered,
        VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
        gwas_report_template,
        VALIDATE_PHENOTYPES.out.phenotypes_file_validated_log,
        covariates_file_validated_log.collect(),
        regenie_step1_parsed_logs_ch.collect(),
        REGENIE_LOG_PARSER_STEP2.out.regenie_step2_parsed_logs
    )
}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

// extract phenotype name from regenie output file.
def getPhenotype(prefix, file ) {
    return file.baseName.replaceAll(prefix + "_", '').replaceAll('.regenie', '')
}
