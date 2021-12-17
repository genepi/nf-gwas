process REGENIE_LOG_PARSER_STEP1 {

  publishDir "${params.outdir}/logs", mode: 'copy'

  input:
    path regenie_step1_log
    path regenie_log_parser_jar

  output:
    path "${params.project}.step1.log", emit: regenie_step1_parsed_logs

  """
  java -jar ${regenie_log_parser_jar} ${regenie_step1_log} --output ${params.project}.step1.log
  """
  }
