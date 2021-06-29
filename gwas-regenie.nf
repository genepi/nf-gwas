params.project = "test-gwas"
params.output = "tests/output/${params.project}"

params.genotypes_typed = "tests/input/example.{bim,bed,fam}"
params.genotypes_imputed = "tests/input/example.bgen"
params.genotypes_imputed_format = "bgen"

params.phenotypes_filename = "tests/input/phenotype.txt"
params.phenotypes_binary_trait = false
params.phenotypes_columns = ["Y1","Y2"]

params.qc_maf = "0.01"
params.qc_mac = "100"
params.qc_geno = "0.1"
params.qc_hwe = "1e-15"
params.qc_mind = "0.1"

params.prune_maf = 0.01
params.prune_window_kbsize = 50
params.prune_step_size = 5
params.prune_r2_threshold = 0.2

params.regenie_step1_bsize = 100
params.regenie_step2_bsize = 200
params.regenie_step2_sample_file = 'NO_FILE'
//only dominant or recessive allowed, default is additive
params.regenie_step2_test = 'additive'
params.regenie_min_imputation_score = 0.00
params.regenie_min_mac = 5
params.threads = (Runtime.runtime.availableProcessors() - 1)

params.gwas_tophits = 50

gwas_report_template = file("$baseDir/reports/gwas_report_template.Rmd")


Channel.fromFilePairs("${params.genotypes_typed}", size: 3).set {genotyped_plink_files_ch}
Channel.fromFilePairs("${params.genotypes_typed}", size: 3).set {genotyped_plink_files_ch2}
phenotype_file_ch = file(params.phenotypes_filename)
phenotype_file_ch2 = file(params.phenotypes_filename)
sample_file_ch = file(params.regenie_step2_sample_file)
regenie_test_ch = file(params.regenie_step2_test)

phenotypes_ch = Channel.from(params.phenotypes_columns)

//convert vcf files to bgen
if (params.genotypes_imputed_format == "vcf"){

  imputed_vcf_files_ch =  Channel.fromPath("${params.genotypes_imputed}")

  process vcfToBgen {

    cpus "${params.threads}"
    publishDir "$params.output/01_quality_control", mode: 'copy'

    input:
      file(imputed_vcf_file) from imputed_vcf_files_ch

    output:
      file "*.bgen" into imputed_files_ch

    """
    plink2 --vcf ${imputed_vcf_file} --threads ${params.threads} --export bgen-1.3 --out ${imputed_vcf_file.baseName}
    """

  }

} else {

  imputed_files_ch =  Channel.fromPath("${params.genotypes_imputed}")

}

process snpPruning {
  publishDir "$params.output/01_quality_control", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_file) from genotyped_plink_files_ch
  output:
    tuple val("${params.project}.pruned"), "${params.project}.pruned.bim", "${params.project}.pruned.bed","${params.project}.pruned.fam" into genotyped_plink_files_pruned_ch
    tuple val("${params.project}.pruned"), "${params.project}.pruned.bim", "${params.project}.pruned.bed","${params.project}.pruned.fam" into genotyped_plink_files_pruned_ch2

  """
# Prune, filter and convert to plink
plink2 --bfile ${genotyped_plink_filename} --double-id --maf "${params.prune_maf}" --indep-pairwise "${params.prune_window_kbsize}" "${params.prune_step_size}" "${params.prune_r2_threshold}" --out ${params.project}
plink2 --bfile ${genotyped_plink_filename} --extract ${params.project}.prune.in --double-id --make-bed --out ${params.project}.pruned
  """

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

process regenieStep1 {

  publishDir "$params.output/02_regenie_step1", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_bim_file), file(genotyped_plink_bed_file), file(genotyped_plink_fam_file) from genotyped_plink_files_pruned_ch2
    file phenotype_file from phenotype_file_ch
    file qcfiles from genotyped_plink_files_qc_ch.collect()

  output:
    file "fit_bin_out*" into fit_bin_out_ch

  """
  regenie \
    --step 1 \
    --bed ${genotyped_plink_filename} \
    --extract ${genotyped_plink_filename}.qc.snplist \
    --keep ${genotyped_plink_filename}.qc.id \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypes_columns.join(',')} \
    --bsize ${params.regenie_step1_bsize} \
    ${params.phenotypes_binary_trait == true ? '--bt' : ''} \
    --lowmem \
    --gz \
    --lowmem-prefix tmp_rg \
    --threads ${params.threads} \
    --out fit_bin_out
  """

}


process regenieStep2 {
	cpus "${params.threads}"
  publishDir "$params.output/03_regenie_step2", mode: 'copy'

  input:
    file imputed_file from imputed_files_ch
    file phenotype_file from phenotype_file_ch2
    file sample_file from sample_file_ch
    file regenie_test from regenie_test_ch
    file fit_bin_out from fit_bin_out_ch.collect()

  output:
    file "gwas_results.*regenie.gz" into gwas_results_ch
  script:
    def bgenSample = sample_file.name != 'NO_FILE' ? "--sample $sample_file" : ''
    def regenieTest = regenie_test.name != 'additive' ? "--test $regenie_test" : ''
  """
  regenie \
    --step 2 \
    --bgen ${imputed_file} \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypes_columns.join(',')} \
    --bsize ${params.regenie_step2_bsize} \
    $regenieTest \
    ${params.phenotypes_binary_trait ? '--bt' : ''} \
    --pred fit_bin_out_pred.list \
    --threads ${params.threads} \
    --minMAC ${params.regenie_min_mac} \
    --minINFO ${params.regenie_min_imputation_score} \
    --split \
    --gz \
    $bgenSample \
    --out gwas_results.${imputed_file.baseName}

  """
}

process mergeRegenie {

publishDir "$params.output/04_regenie_merged", mode: 'copy'

  input:
  file regenie_chromosomes from gwas_results_ch.collect()
  val phenotype from phenotypes_ch

  output:
  file "${params.project}.*.regenie.gz" into regenie_merged_ch
  file "${params.project}.*.regenie.gz" into regenie_merged_ch2


  """
  # static header due to split
  ls -1v ${regenie_chromosomes} | head -n 1 | xargs cat | zgrep -hE 'CHROM' | gzip > header.gz
  ls -1v  ${regenie_chromosomes} | ls *_${phenotype}.regenie.gz | xargs cat | zgrep -hE '^[0-9]' | gzip > chromosomes_data_${phenotype}.regenie.gz
  cat header.gz chromosomes_data_${phenotype}.regenie.gz > ${params.project}.${phenotype}.regenie.gz
  """

}

process gwasTophits {

publishDir "$params.output/05_regenie_filtered", mode: 'copy'

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
  file regenie_merged from regenie_merged_ch.collect()
  file gwas_report_template

  output:
  file "*.html" into report_ch

  """
  Rscript -e "require( 'rmarkdown' ); render('${gwas_report_template}',
    params = list(
      project = '${params.project}',
      regenie_merged = '${regenie_merged}',
      phenotype='${params.phenotypes_columns.join(',')}'
    ), knit_root_dir='\$PWD', output_file='\$PWD/05_gwas_report.html')"
  """
}


//TODO: process annotate

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
