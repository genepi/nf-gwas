process IMPUTED_TO_PLINK2 {

  label 'process_plink2'

  input:
    path imputed_vcf_file

  output:
    tuple val("${imputed_vcf_file.baseName}"), path("${imputed_vcf_file.baseName}.pgen"), path("${imputed_vcf_file.baseName}.psam"),path("${imputed_vcf_file.baseName}.pvar"), emit: imputed_plink2

"""
plink2 \
  --vcf $imputed_vcf_file dosage=DS \
  --make-pgen \
  --double-id \
  --out ${imputed_vcf_file.baseName} \
  --threads ${task.cpus} \
  --memory ${task.memory.toMega()}
"""
}
