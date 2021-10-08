process REGENIE_VALIDATE_PHENOTYPES {

  input:
  path phenotypes_file
  path regenie_validate_input_jar

  output:
  path "${phenotypes_file.baseName}.updated.txt", emit: phenotypes_file_validated
  path "${phenotypes_file.baseName}.updated.log", emit: phenotypes_file_validated_log

  """
  java -jar ${regenie_validate_input_jar}  --input ${phenotypes_file} --output  ${phenotypes_file.baseName}.updated.txt --type phenotype
  """
  }
