process PARSE_REGENIE_LOG_STEP2 {

publishDir "${params.outdir}/regenie_logs", mode: 'copy'

  input:
  path regenie_step2_logs
  path regenie_log_parser_jar

  output:
  path "${params.project}.step2.log", emit: logs_step2_ch

  """
  java -jar ${regenie_log_parser_jar} ${regenie_step2_logs} --output ${params.project}.step2.log
  """

}
