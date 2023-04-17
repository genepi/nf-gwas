//check deprecated option
ANSI_RESET = "\u001B[0m"
ANSI_YELLOW = "\u001B[33m"

if(params.genotypes_imputed){
genotypes_association = params.genotypes_imputed
println ANSI_YELLOW + "WARN: Option genotypes_imputed is deprecated. Please use genotypes_association instead." + ANSI_RESET
} else {
genotypes_association = params.genotypes_association
}

genotypes_association_manifest = params.genotypes_imputed_manifest
//TODO Move to files and use correct one depending on genotype format (1 vs chr1)
genotypes_imputed_chunks = params.genotypes_imputed_chunks

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

if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

phenotypes_array = params.phenotypes_columns.trim().split(',')

r_functions_file = file("$baseDir/reports/functions.R",checkIfExists: true)
rmd_pheno_stats_file = file("$baseDir/reports/child_phenostatistics.Rmd",checkIfExists: true)
rmd_valdiation_logs_file = file("$baseDir/reports/child_validationlogs.Rmd",checkIfExists: true)

//Annotation files
genes_hg19 = file("$baseDir/genes/genes.GRCh37.sorted.bed", checkIfExists: true)
genes_hg38 = file("$baseDir/genes/genes.GRCh38.sorted.bed", checkIfExists: true)

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
Channel.fromFilePairs(genotypes_prediction, size: 3).set {genotyped_plink_ch}
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

          if(!genotypes_association_manifest) {

          //no conversion needed (already BGEN), set input to imputed_plink2_ch channel
          // -1 denotes that no range is applied
          channel.fromPath(genotypes_association)
          .map { tuple(it.baseName, it, [], [], -1) }
          .set {imputed_plink2_ch}

          } else {
            
            if(!genotypes_imputed_chunks){
              println("SPECIFY CHUNKS!")
            }

            Channel
              .fromPath(genotypes_imputed_chunks)
              .splitCsv(header:true, sep:'\t')
              .map(row -> tuple(row['CONTIG'], row['RANGE']))
              .set { chunks }

            Channel
              .fromPath(genotypes_association_manifest)
              .splitCsv(header:false, sep:'\t')
              .map(row -> tuple("${row[0]}",file("${row[1]}"),file("${row[1]}").baseName))
              .set { manifest }

          
            manifest.combine(chunks, by: 0)
              .map{ row -> tuple(row[2],file(row[1]),[],[],row[3]) }
              .set {imputed_plink2_ch}
                    }

      }

    //gene-based tests
    } else {

      if (genotypes_association_format == 'bed') {

        Channel.fromFilePairs(genotypes_association, size: 3).set {step2_gene_tests_ch}

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

    } else {

      REGENIE_STEP2 (
          regenie_step1_out_ch.collect(),
          imputed_plink2_ch,
          genotypes_association_format,
          VALIDATE_PHENOTYPES.out.phenotypes_file_validated,
          sample_file,
          covariates_file_validated,
          condition_list_file
      )

      regenie_step2_log_ch = REGENIE_STEP2.out.regenie_step2_out_log
      regenie_step2_out_ch = REGENIE_STEP2.out.regenie_step2_out

    }

    REGENIE_LOG_PARSER_STEP2 (
        regenie_step2_log_ch.collect()
    )

    if(rsids == null) {
      DOWNLOAD_RSIDS()
      annotation_files =  DOWNLOAD_RSIDS.out.rsids_ch
    } else {
      annotation_files = tuple(rsids_file, rsids_tbi_file)
    }

    if (!run_gene_tests) {

      ANNOTATE_RESULTS (
      regenie_step2_out_ch.transpose(),
      genes_hg19,
      genes_hg38,
      annotation_files,
      association_build
      )

     // regenie creates a file for each tested phenotype. Merge-steps require to group by phenotype.
      ANNOTATE_RESULTS.out.annotated_ch
      .map { prefix, fl -> tuple(getPhenotype(prefix, fl), fl) }
      .set { regenie_step2_by_phenotype }

    } else {
      regenie_step2_out_ch
      .transpose()
      .map { prefix, fl -> tuple(getPhenotype(prefix, fl), fl) }
      .set { regenie_step2_by_phenotype }

   
    }
 


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
        regenie_step2_by_phenotype
  )

    MERGE_RESULTS_FILTERED (
        FILTER_RESULTS.out.results_filtered.groupTuple()
  )

    //TODO: change with list coming from new interactive manhattan plot
    //combined merge results and annotated filtered results by phenotype (index 0)
    merged_results_and_annotated_filtered =  MERGE_RESULTS.out.results_merged
                                                .combine( MERGE_RESULTS_FILTERED.out.results_filtered_merged, by: 0)

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

   // create a tuple(phenotype, annotated, htmlreport) that can be used to create index.html
   annotated_phenotypes =  MERGE_RESULTS.out.results_merged
                                 .combine(REPORT.out.phenotype_report, by: 0)

    annotated_phenotypes
      .map{ row -> row[0] }
      .set { annotated_phenotypes_phenotypes }

    annotated_phenotypes
      .map{ row -> row[1] }
      .set { annotated_phenotypes_files }

    annotated_phenotypes
      .map{ row -> row[2] }
      .set { annotated_phenotypes_reports }


    REPORT_INDEX (
      annotated_phenotypes_phenotypes.collect(),
      annotated_phenotypes_files.collect(),
      annotated_phenotypes_reports.collect(),
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
    return file.baseName.split('_')[1].replaceAll('.regenie', '')
}
