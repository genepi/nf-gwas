process PARSE_REGENIE_LOG_STEP1 {

publishDir "${params.outdir}/regenie_logs", mode: 'copy'

  input:
  path regenie_step1_log
  path regenie_log_parser_jar

  output:
  path "${params.project}.step1.log", emit: logs_step1_ch

  """
  java -jar ${regenie_log_parser_jar} ${regenie_step1_log} --output ${params.project}.step1.log
  """
  }
