process REGENIE_VALIDATE_COVARIATS {

publishDir "${params.outdir}/test", mode: 'copy'

  input:
  path covariates_file
  path regenie_validate_input_jar

  output:
  path "${covariates_file.baseName}.updated.txt", emit: covariates_file_validated
  path "${covariates_file.baseName}.updated.log", emit: covariates_file_validated_log

  """
  java -jar ${regenie_validate_input_jar} --input ${covariates_file} --output  ${covariates_file.baseName}.updated.txt --type covariate
  """
  }
