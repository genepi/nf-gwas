process REGENIE_VALIDATE_COVARIATS {

publishDir "${params.outdir}/test", mode: 'copy'

  input:
  path covariates_file
  path regenie_validate_phenotypes_jar

  output:
  path "${covariates_file.baseName}.updated.txt", emit: covariates_file_validated

  """
  java -jar ${regenie_validate_phenotypes_jar} --input ${covariates_file} --output  ${covariates_file.baseName}.updated.txt
  """
  }
