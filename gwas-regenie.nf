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


process CACHE_JBANG_SCRIPTS {

  input:
    path regenie_log_parser
    path regenie_filter

  output:
    path "RegenieLogParser.jar", emit: regenie_log_parser_jar
    path "RegenieFilter.jar", emit: regenie_filter_jar

  """
  jbang export portable -O=RegenieLogParser.jar ${regenie_log_parser}
  jbang export portable -O=RegenieFilter.jar ${regenie_filter}
  """

}

//convert vcf files to plink2 format
  process VCF_TO_PLINK2 {

    cpus "${params.threads}"
    publishDir "$outdir/01_quality_control", mode: 'copy'

    input:
      path imputed_vcf_file

    output:
      tuple val("${imputed_vcf_file.baseName}"), path("${imputed_vcf_file.baseName}.pgen"), path("${imputed_vcf_file.baseName}.psam"),path("${imputed_vcf_file.baseName}.pvar"), emit: imputed_plink

    """
    plink2 \
      --vcf $imputed_vcf_file dosage=DS \
      --threads ${params.threads} \
      --make-pgen \
      --double-id \
      --out ${imputed_vcf_file.baseName}
    """
  }

process SNP_PRUNING {
//  publishDir "$params.output/01_quality_control", mode: 'copy'

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file)
  output:
    tuple val("${params.project}.pruned"), path("${params.project}.pruned.bim"), path("${params.project}.pruned.bed"),path("${params.project}.pruned.fam"), emit: genotypes_pruned

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

process QUALITY_CONTROL_FILTERS {

  //publishDir "$params.output/01_quality_control", mode: 'copy'

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)

  output:
    path "${genotyped_plink_filename}.qc.*", emit: genotyped_qc

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

process REGENIE_STEP1 {

  //publishDir "$outdir/02_regenie_step1", mode: 'copy'

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)
    path phenotype_file
    path qcfiles
    path covariate_file

  output:
    path "fit_bin_out*", emit: fit_bin_out_ch
    path "fit_bin_out*log", emit: fit_bin_log_ch

  script:
  def covariants = covariate_file.name != 'NO_COV_FILE' ? "--covarFile $covariate_file --covarColList ${covariates_array.join(',')}" : ''
  def deleteMissings = params.phenotypes_delete_missings  ? "--strict" : ''
  """
  regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --extract ${genotyped_plink_filename}.qc.snplist \
    --keep ${genotyped_plink_filename}.qc.id \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${phenotypes_array.join(',')} \
    $covariants \
    $deleteMissings \
    --bsize ${params.regenie_bsize_step1} \
    ${params.phenotypes_binary_trait == true ? '--bt' : ''} \
    --lowmem \
    --gz \
    --lowmem-prefix tmp_rg \
    --threads ${params.threads} \
    --out fit_bin_out
  """

}

process PARSE_REGENIE_LOG_STEP1 {

publishDir "$outdir/regenie_logs", mode: 'copy'

  input:
  path regenie_step1_log
  path regenie_log_parser_jar

  output:
  path "${params.project}.step1.log", emit: logs_step1_ch

  """
  java -jar ${regenie_log_parser_jar} ${regenie_step1_log} --output ${params.project}.step1.log
  """
  }

process REGENIE_STEP2 {
	cpus "${params.threads}"
  tag "${filename}"
  //publishDir "$outdir/03_regenie_step2", mode: 'copy'

  input:
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file)
    path phenotype_file
    path sample_file
    path fit_bin_out
    path covariate_file

  output:
    path "gwas_results.*regenie.gz", emit: gwas_results_ch
    path "gwas_results.${filename}*log", emit: gwas_results_ch2
  script:
    def format = params.genotypes_imputed_format == 'bgen' ? "--bgen" : '--pgen'
    def extension = params.genotypes_imputed_format == 'bgen' ? ".bgen" : ''
    def bgen_sample = sample_file.name != 'NO_SAMPLE_FILE' ? "--sample $sample_file" : ''
    def test = "--test $params.regenie_test"
    def range = params.regenie_range != '' ? "--range $params.regenie_range" : ''
    def covariants = covariate_file.name != 'NO_COV_FILE' ? "--covarFile $covariate_file --covarColList ${covariates_array.join(',')}" : ''
    def deleteMissingData = params.phenotypes_delete_missings  ? "--strict" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""


  """
  regenie \
    --step 2 \
    $format ${filename}${extension} \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${phenotypes_array.join(',')} \
    --bsize ${params.regenie_bsize_step2} \
    ${params.phenotypes_binary_trait ? '--bt  --firth 0.01 --approx' : ''} \
    --pred fit_bin_out_pred.list \
    --threads ${params.threads} \
    --minMAC ${params.regenie_min_mac} \
    --minINFO ${params.regenie_min_imputation_score} \
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

process FILTER_RESULTS {

//publishDir "$params.output/regenie_results", mode: 'copy'
tag "${regenie_chromosomes.baseName}"

  input:
  path regenie_chromosomes
  path regenie_filter_jar

  output:
  path "${regenie_chromosomes.baseName}.filtered*", emit: gwas_results_filtered_ch
  path "${regenie_chromosomes}", emit: gwas_results_unfiltered_ch

  """
  java -jar ${regenie_filter_jar} --input ${regenie_chromosomes} --limit ${params.min_pvalue} --output ${regenie_chromosomes.baseName}.filtered
  #todo: CSVWriter for gzip
  gzip ${regenie_chromosomes.baseName}.filtered
  """

}

process PARSE_REGENIE_LOG_STEP2 {

publishDir "$outdir/regenie_logs", mode: 'copy'

  input:
  path regenie_step2_logs
  path regenie_log_parser_jar

  output:
  path "${params.project}.step2.log", emit: logs_step2_ch

  """
  java -jar ${regenie_log_parser_jar} ${regenie_step2_logs} --output ${params.project}.step2.log
  """

}

process MERGE_RESULTS_FILTERED {

publishDir "$outdir/regenie_results", mode: 'copy'
tag "${phenotype}"

  input:
  path regenie_chromosomes
  val phenotype

  output:
    path "${params.project}.*.regenie.filtered.gz", emit: regenie_merged_filtered_ch


  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs cat | zgrep -hE 'CHROM' | gzip > header.gz
  ls -1v  ${regenie_chromosomes} | ls *_${phenotype}.regenie.filtered.gz | xargs cat | zgrep -hE '^[0-9]' | gzip > chromosomes_data_${phenotype}.regenie.tmp.gz
  cat header.gz chromosomes_data_${phenotype}.regenie.tmp.gz > ${params.project}.${phenotype}.regenie.filtered.gz
  rm chromosomes_data_${phenotype}.regenie.tmp.gz
  """

}

process MERGE_RESULTS_UNFILTERED {

publishDir "$outdir/regenie_results", mode: 'copy'
tag "${phenotype}"

  input:
  path regenie_chromosomes
  val phenotype

  output:
  tuple val(phenotype), path ("${params.project}.${phenotype}.regenie.all.gz"), emit: regenie_merged_unfiltered_ch


  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs cat | zgrep -hE 'CHROM' | gzip > header.gz
  ls -1v  ${regenie_chromosomes} | ls *_${phenotype}.regenie.gz | xargs cat | zgrep -hE '^[0-9]' | gzip > chromosomes_data_${phenotype}.regenie.tmp.gz
  cat header.gz chromosomes_data_${phenotype}.regenie.tmp.gz > ${params.project}.${phenotype}.regenie.all.gz
  rm chromosomes_data_${phenotype}.regenie.tmp.gz
  """

}

process GWAS_TOPHITS {

  input:
  path regenie_merged

  output:
  path "${regenie_merged.baseName}.tophits.gz", emit: tophits_ch


  """
  #!/bin/bash
  set -e
  (zcat ${regenie_merged} | head -n 1 && zcat ${regenie_merged} | tail -n +2 | sort -T $PWD/work -k12 --general-numeric-sort --reverse) | gzip > ${regenie_merged.baseName}.sorted.gz
  zcat ${regenie_merged.baseName}.sorted.gz | head -n ${params.tophits} | gzip > ${regenie_merged.baseName}.tophits.gz
  rm ${regenie_merged.baseName}.sorted.gz
  """

}

process ANNOTATE_TOPHITS {

publishDir "$outdir/regenie_tophits_annotated", mode: 'copy'

  input:
  path tophits
  path genes_hg19
  path genes_hg38

  output:
  path "${tophits.baseName}.annotated.txt.gz", emit: annotated_ch

  def genes = params.genotypes_build == 'hg19' ? "${genes_hg19}" : "${genes_hg38}"

  """
  #!/bin/bash
  set -e
  # sort lexicographically
  zcat ${tophits} | awk 'NR == 1; NR > 1 {print \$0 | "sort -k1,1 -k2,2n"}' > ${tophits.baseName}.sorted.txt
  sed -e 's/ /\t/g'  ${tophits.baseName}.sorted.txt > ${tophits.baseName}.sorted.tabs.txt
  rm ${tophits.baseName}.sorted.txt
  # remove header line for cloest-features
  sed 1,1d ${tophits.baseName}.sorted.tabs.txt > ${tophits.baseName}.sorted.tabs.fixed.txt
  # save header line
  head -n 1 ${tophits.baseName}.sorted.tabs.txt > ${tophits.baseName}.header.txt
  rm ${tophits.baseName}.sorted.tabs.txt
  # create final header
  sed ' 1 s/.*/&\tGENE_CHROMOSOME\tGENE_START\tGENE_END\tGENE_NAME\tGENE_DISTANCE/' ${tophits.baseName}.header.txt > ${tophits.baseName}.header.fixed.txt
  closest-features --dist --delim '\t' --shortest ${tophits.baseName}.sorted.tabs.fixed.txt ${genes} > ${tophits.baseName}.closest.txt
  cat ${tophits.baseName}.header.fixed.txt ${tophits.baseName}.closest.txt > ${tophits.baseName}.closest.merged.txt
  rm ${tophits.baseName}.sorted.tabs.fixed.txt
  rm ${tophits.baseName}.header.fixed.txt
  rm ${tophits.baseName}.header.txt
  # sort by p-value again
  (cat ${tophits.baseName}.closest.merged.txt | head -n 1 && cat ${tophits.baseName}.closest.merged.txt | tail -n +2 | sort -k12 --general-numeric-sort --reverse) | gzip > ${tophits.baseName}.annotated.txt.gz
  rm ${tophits.baseName}.closest.merged.txt
  """

}

process GWAS_REPORT {

publishDir "$outdir", mode: 'copy'

  memory '5 GB'

  input:
  tuple val(phenotype), path(regenie_merged)
	path phenotype_file
  path gwas_report_template
  path step1_log
  path step2_log

  output:
  path "*.html"

  """
  Rscript -e "require( 'rmarkdown' ); render('${gwas_report_template}',
    params = list(
      project = '${params.project}',
      date = '${params.project_date}',
      version = '$workflow.manifest.version',
      regenie_merged='${regenie_merged}',
      regenie_filename='${regenie_merged.baseName}',
      phenotype_file='${phenotype_file}',
      phenotype='${phenotype}',
      covariates='${params.covariates_columns.join(',')}',
      regenie_step1_log='${step1_log}',
      regenie_step2_log='${step2_log}'
    ), intermediates_dir='\$PWD', knit_root_dir='\$PWD', output_file='\$PWD/${regenie_merged.baseName}.html')"
  """
}

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
