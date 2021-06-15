params.project = "test-gwas"
params.output = "tests/output"
params.genotyped = "tests/input/example.{bim,bed,fam}"
params.imputed = "tests/input/example.bgen"
params.phenotypeFile = "tests/input/phenotype.txt"
params.phenotypeBinary = false
params.phenotypeColumns = "Y1"

params.qcMaf = "0.01"
params.qcMac = "100"
params.qcGeno = "0.1"
params.qcHwe = "1e-15"
params.qcMind = "0.1"

params.bsizeStep1 = 100
params.bsizeStep2 = 200
params.pThreshold = 0.01

Channel.fromFilePairs("${params.genotyped}", size: 3).set {genotyped_plink_files_ch}
Channel.fromFilePairs("${params.genotyped}", size: 3).set {genotyped_plink_files_ch2}
imputed_files_ch =  Channel.fromPath("${params.imputed}")
phenotype_file_ch = file(params.phenotypeFile)
phenotype_file_ch2 = file(params.phenotypeFile)


process qualityControl {

  publishDir "$params.output/01_quality_control", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_file) from genotyped_plink_files_ch

  output:
    file "${genotyped_plink_filename}.qc.*" into genotyped_plink_files_qc_ch

  """
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --maf ${params.qcMaf} \
    --mac ${params.qcMac} \
    --geno ${params.qcGeno} \
    --hwe ${params.qcHwe} \
    --mind ${params.qcMind} \
    --write-snplist --write-samples --no-id-header \
    --out ${genotyped_plink_filename}.qc
  """

}


process regenieStep1 {

  publishDir "$params.output/02_regenie_step1", mode: 'copy'

  input:
    set genotyped_plink_filename, file(genotyped_plink_file) from genotyped_plink_files_ch2
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
    --phenoColList  ${params.phenotypeColumns} \
    --bsize ${params.bsizeStep1} \
    ${params.phenotypeBinary ? '--bt' : ''} \
    --lowmem \
    --lowmem-prefix tmp_rg \
    --out fit_bin_out
  """

}


process regenieStep2 {

  publishDir "$params.output/03_regenie_step2", mode: 'copy'

  input:
    file imputed_file from imputed_files_ch
    file phenotype_file from phenotype_file_ch2
    file fit_bin_out from fit_bin_out_ch.collect()

  output:
    file "gwas_results.*" into gwas_results_ch

  """
  regenie \
    --step 2 \
    --bgen ${imputed_file} \
    --phenoFile ${phenotype_file} \
    --phenoColList  ${params.phenotypeColumns} \
    --bsize ${params.bsizeStep2} \
    ${params.phenotypeBinary ? '--bt' : ''} \
    --firth --approx \
    --pThresh ${params.pThreshold} \
    --pred fit_bin_out_pred.list \
    --out gwas_results.${imputed_file.baseName}

  """

}

//TODO: process manhattanPlot
//TODO: process annotate

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
