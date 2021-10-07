process REGENIE_VALIDATE_PHENOTYPES {

publishDir "${params.outdir}/test", mode: 'copy'

  input:
  path phenotype_file
  path regenie_validate_phenotypes_jar

  output:
  path "${phenotype_file.baseName}.updated.txt", emit: phenotype_file_validated

  """
  java -jar ${regenie_validate_phenotypes_jar}  --input ${phenotype_file} --output  ${phenotype_file.baseName}.updated.txt
  """
  }
