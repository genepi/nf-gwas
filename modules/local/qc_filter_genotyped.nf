process QC_FILTER_GENOTYPED {

  publishDir "${params.outdir}/logs", mode: 'copy', pattern: '*.qc.log'
  label 'process_plink2'

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file)

  output:
    path "${genotyped_plink_filename}.qc.log"
    path "${genotyped_plink_filename}.qc.snplist", emit: genotyped_filtered_snplist_ch
    path "${genotyped_plink_filename}.qc.id", emit: genotyped_filtered_id_ch
    tuple val("${genotyped_plink_filename}.qc"), path("${genotyped_plink_filename}.qc.bim"), path("${genotyped_plink_filename}.qc.bed"),path("${genotyped_plink_filename}.qc.fam"), emit: genotyped_filtered_files_ch


  """
  plink2 \
    --bfile ${genotyped_plink_filename} \
    --maf ${params.qc_maf} \
    --mac ${params.qc_mac} \
    --geno ${params.qc_geno} \
    --hwe ${params.qc_hwe} \
    --mind ${params.qc_mind} \
    --write-snplist --write-samples --no-id-header \
    --out ${genotyped_plink_filename}.qc \
    --make-bed \
    --threads ${task.cpus} \
    --memory ${task.memory.toMega()}
  """

}
