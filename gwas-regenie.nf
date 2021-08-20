params.project = "test-gwas"
params.project_date = "`date`"
params.version = "v0.0.1"
params.output = "tests/output/${params.project}"

params.genotypes_typed = "tests/input/example.{bim,bed,fam}"
params.genotypes_imputed = "tests/input/example.bgen"
params.genotypes_imputed_format = "bgen"

params.phenotypes_filename = "tests/input/phenotype.txt"
params.phenotypes_binary_trait = false
params.phenotypes_columns = ["Y1","Y2"]
params.covariates_filename = 'NO_COV_FILE'
params.covariates_columns = []

//removing samples with missing data at any of the phenotypes
params.phenotypes_delete_missing_data = false

params.threads = (Runtime.runtime.availableProcessors() - 1)

Channel.fromFilePairs("${params.genotypes_typed}", size: 3).set {genotyped_plink_files_ch}
Channel.fromFilePairs("${params.genotypes_typed}", size: 3).set {genotyped_plink_files_ch2}

RegenieLogParser = "$baseDir/bin/RegenieLogParser.java"

/** params step snpPruning **/
params.prune_exec = false
params.prune_maf = 0.01
params.prune_window_kbsize = 50
params.prune_step_size = 5
params.prune_r2_threshold = 0.2

/** params step qualityControl **/
params.qc_maf = "0.01"
params.qc_mac = "100"
params.qc_geno = "0.1"
params.qc_hwe = "1e-15"
params.qc_mind = "0.1"

/** params step regenieStep1 **/
params.regenie_step1_bsize = 1000

/** params step regenieStep2 **/
params.regenie_step2_bsize = 400
params.regenie_step2_sample_file = 'NO_SAMPLE_FILE'
// skip reading the file specified by --pred
params.regenie_step2_skip_predictions = false
params.regenie_step2_min_imputation_score = 0.00
params.regenie_step2_min_mac = 5
//additive, dominant or recessive allowed. default is additive
params.regenie_step2_test_model = 'additive'
//range for variants to test: CHR:MINPOS-MAXPOS
params.regenie_step2_range = ''

/** params step gwasTophits **/
params.gwas_tophits = 50

/** params step gwasReport **/
gwas_report_template = file("$baseDir/reports/gwas_report_template.Rmd")
phenotype_report_template = file("$baseDir/reports/phenotype_report_template.Rmd")


//phenotypes
phenotype_file = file(params.phenotypes_filename)
if (!phenotype_file.exists()){
  exit 1, "Phenotype file ${params.phenotypes_filename} not found."
}
phenotypes_ch = Channel.from(params.phenotypes_columns)

//optional covariates
covariate_file = file(params.covariates_filename)
if (params.covariates_filename != 'NO_COV_FILE' && !covariate_file.exists()){
  exit 1, "Covariate file ${params.covariates_filename} not found."
}

//optional sample file
sample_file = file(params.regenie_step2_sample_file)
if (params.regenie_step2_sample_file != 'NO_SAMPLE_FILE' && !sample_file.exists()){
  exit 1, "Sample file ${params.regenie_step2_sample_file} not found."
}

//check test model
if (params.regenie_step2_test_model != 'additive' && params.regenie_step2_test_model != 'recessive' && params.regenie_step2_test_model != 'dominant'){
  exit 1, "Test model ${params.regenie_step2_test_model} not supported."
}

//check imputed file format
if (params.genotypes_imputed_format != 'vcf' && params.genotypes_imputed_format != 'bgen'){
  exit 1, "File format ${params.genotypes_imputed_format} not supported."
}

//convert vcf files to plink2 format
if (params.genotypes_imputed_format == "vcf"){

  imputed_vcf_files_ch =  Channel.fromPath("${params.genotypes_imputed}")

  process vcfToPlink2 {

    cpus "${params.threads}"
    publishDir "$params.output/01_quality_control", mode: 'copy'

    input:
      file(imputed_vcf_file) from imputed_vcf_files_ch

    output:
      tuple val("${imputed_vcf_file.baseName}"), "${imputed_vcf_file.baseName}.pgen", "${imputed_vcf_file.baseName}.psam","${imputed_vcf_file.baseName}.pvar" into imputed_files_ch

    """
    plink2 \
      --vcf ${imputed_vcf_file} dosage=DS \
      --threads ${params.threads} \
      --make-pgen \
      --double-id \
      --out ${imputed_vcf_file.baseName}
    """

  }

} else {

  Channel.fromPath(params.genotypes_imputed)
    .map { tuple(it.baseName, it, file('dummy_a'), file('dummy_b')) }
    .set {imputed_files_ch}

}

if(params.prune_exec) {

process snpPruning {
  publishDir "$params.output/01_quality_control", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_file) from genotyped_plink_files_ch
  output:
    tuple val("${params.project}.pruned"), "${params.project}.pruned.bim", "${params.project}.pruned.bed","${params.project}.pruned.fam" into genotyped_plink_files_pruned_ch
    tuple val("${params.project}.pruned"), "${params.project}.pruned.bim", "${params.project}.pruned.bed","${params.project}.pruned.fam" into genotyped_plink_files_pruned_ch2

  """
  # Prune, filter and convert to plink
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --double-id --maf ${params.prune_maf} \
    --indep-pairwise ${params.prune_window_kbsize} ${params.prune_step_size} ${params.prune_r2_threshold} \
    --out ${params.project}
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --extract ${params.project}.prune.in \
    --double-id \
    --make-bed \
    --out ${params.project}.pruned
  """

}
} else {

  Channel.fromFilePairs("${params.genotypes_typed}", size: 3, flat: true).set {genotyped_plink_files_pruned_ch}
  Channel.fromFilePairs("${params.genotypes_typed}", size: 3, flat: true).set {genotyped_plink_files_pruned_ch2}

}


process qualityControl {

  publishDir "$params.output/01_quality_control", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_bim_file), file(genotyped_plink_bed_file), file(genotyped_plink_fam_file) from genotyped_plink_files_pruned_ch

  output:
    file "${genotyped_plink_filename}.qc.*" into genotyped_plink_files_qc_ch

  """
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --maf ${params.qc_maf} \
    --mac ${params.qc_mac} \
    --geno ${params.qc_geno} \
    --hwe ${params.qc_hwe} \
    --mind ${params.qc_mind} \
    --write-snplist --write-samples --no-id-header \
    --out ${genotyped_plink_filename}.qc
  """

}

if (!params.regenie_step2_skip_predictions){
process regenieStep1 {

  publishDir "$params.output/02_regenie_step1", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_bim_file), file(genotyped_plink_bed_file), file(genotyped_plink_fam_file) from genotyped_plink_files_pruned_ch2
    file phenotype_file
    file qcfiles from genotyped_plink_files_qc_ch.collect()
    file covariate_file

  output:
    file "fit_bin_out*" into fit_bin_out_ch
    file "fit_bin_out*log" into fit_bin_log_ch

  script:
  def covariants = covariate_file.name != 'NO_COV_FILE' ? "--covarFile $covariate_file --covarColList ${params.covariates_columns.join(',')}" : ''
  def deleteMissingData = params.phenotypes_delete_missing_data  ? "--strict" : ''
  """
  regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --extract ${genotyped_plink_filename}.qc.snplist \
    --keep ${genotyped_plink_filename}.qc.id \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypes_columns.join(',')} \
    $covariants \
    $deleteMissingData \
    --bsize ${params.regenie_step1_bsize} \
    ${params.phenotypes_binary_trait == true ? '--bt' : ''} \
    --lowmem \
    --gz \
    --lowmem-prefix tmp_rg \
    --threads ${params.threads} \
    --out fit_bin_out
  """

}


process parseRegenieLogStep1 {

publishDir "$params.output/04_regenie_log", mode: 'copy'

  input:
  file regenie_step1_log from fit_bin_log_ch.collect()

  output:
  file "${params.project}.step1.log" into logs_step1_ch

  """
  jbang ${RegenieLogParser} ${regenie_step1_log} --output ${params.project}.step1.log
  """
  }
  } else {

    fit_bin_out_ch = Channel.from(["fit_bin_out_ch_dummy"]).collect()

    logs_step1_ch = Channel.from([""]).collect()

  }


process regenieStep2 {
	cpus "${params.threads}"
  publishDir "$params.output/03_regenie_step2", mode: 'copy'

  input:
    set filename, file(plink2_pgen_file), file(plink2_psam_file), file(plink2_pvar_file) from imputed_files_ch
    file phenotype_file
    file sample_file
    file fit_bin_out from fit_bin_out_ch.collect()
    file covariate_file

  output:
    file "gwas_results.*regenie.gz" into gwas_results_ch
    file "gwas_results.${filename}*log" into gwas_results_ch2
  script:
    def format = params.genotypes_imputed_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = params.genotypes_imputed_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file.name != 'NO_SAMPLE_FILE' ? "--sample $sample_file" : ''
    def test = params.regenie_step2_test_model != 'additive' ? "--test $params.regenie_step2_test_model" : ''
    def range = params.regenie_step2_range != '' ? "--range $params.regenie_step2_range" : ''
    def covariants = covariate_file.name != 'NO_COV_FILE' ? "--covarFile $covariate_file --covarColList ${params.covariates_columns.join(',')}" : ''
    def deleteMissingData = params.phenotypes_delete_missing_data  ? "--strict" : ''
    def predictions = params.regenie_step2_skip_predictions  ? '--ignore-pred' : ""


  """
  regenie \
    --step 2 \
    $format ${filename}${extension} \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypes_columns.join(',')} \
    --bsize ${params.regenie_step2_bsize} \
    ${params.phenotypes_binary_trait ? '--bt  --firth 0.01 --approx' : ''} \
    --pred fit_bin_out_pred.list \
    --threads ${params.threads} \
    --minMAC ${params.regenie_step2_min_mac} \
    --minINFO ${params.regenie_step2_min_imputation_score} \
    --gz \
    $test \
    $bgen_sample \
    $range \
    $covariants \
    $deleteMissingData \
    $predictions \
    --out gwas_results.${filename}

  """
}

process parseRegenieLogStep2 {

publishDir "$params.output/04_regenie_log", mode: 'copy'

  input:
  file regenie_step2_logs from gwas_results_ch2.collect()

  output:
  file "${params.project}.step2.log" into logs_step2_ch

  """
  jbang ${RegenieLogParser} ${regenie_step2_logs} --output ${params.project}.step2.log
  """

}

process mergeRegenie {

publishDir "$params.output/05_regenie_merged", mode: 'copy'

  input:
  file regenie_chromosomes from gwas_results_ch.collect()
  val phenotype from phenotypes_ch

  output:
  tuple  phenotype, val("${params.project}.${phenotype}.regenie.gz"), "${params.project}.${phenotype}.regenie.gz" into regenie_merged_ch
  file "${params.project}.*.regenie.gz" into regenie_merged_ch2


  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs cat | zgrep -hE 'CHROM' | gzip > header.gz
  ls -1v  ${regenie_chromosomes} | ls *_${phenotype}.regenie.gz | xargs cat | zgrep -hE '^[0-9]' | gzip > chromosomes_data_${phenotype}.regenie.gz
  cat header.gz chromosomes_data_${phenotype}.regenie.gz > ${params.project}.${phenotype}.regenie.gz
  """

}

process gwasTophits {

publishDir "$params.output/06_regenie_filtered", mode: 'copy'

  input:
  file regenie_merged from regenie_merged_ch2

  output:
  file "${regenie_merged.baseName}.sorted.filtered.gz" into filtered_ch


  """
  #todo: replace by jbang script
  (zcat ${regenie_merged} | head -n 1 && zcat ${regenie_merged} | tail -n +2 | sort -k12 --general-numeric-sort --reverse) | gzip > ${regenie_merged.baseName}.sorted.gz
  zcat ${regenie_merged.baseName}.sorted.gz | head -n ${params.gwas_tophits} | gzip > ${regenie_merged.baseName}.sorted.filtered.gz
  """

}

process gwasReport {

publishDir "$params.output", mode: 'copy'

  input:
  set phenotype, regenie_merged_name, regenie_merged from regenie_merged_ch
	file phenotype_file
  file gwas_report_template
  file step1_log from logs_step1_ch
  file step2_log from logs_step2_ch

  output:
  file "*.html"

  """
  Rscript -e "require( 'rmarkdown' ); render('${gwas_report_template}',
    params = list(
      project = '${params.project}',
      date = '${params.project_date}',
      version = '${params.version}',
      regenie_merged='${regenie_merged}',
      regenie_filename='${regenie_merged_name}',
      phenotype_file='${phenotype_file}',
      phenotype='${phenotype}',
      covariates='${params.covariates_columns.join(',')}',
      regenie_step1_log='${step1_log}',
      regenie_step2_log='${step2_log}'
    ), knit_root_dir='\$PWD', output_file='\$PWD/07_${regenie_merged.baseName}.html')"
  """
}


//TODO: process annotate

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
