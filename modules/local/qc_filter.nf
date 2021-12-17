process QC_FILTER {

  label 'process_plink2'

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_bim_file), path(genotyped_plink_bed_file), path(genotyped_plink_fam_file)

  output:
    path "${genotyped_plink_filename}.qc.*", emit: genotyped_filtered

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
    --threads ${task.cpus} \
    --memory ${task.memory.toMega()}
  """

}
