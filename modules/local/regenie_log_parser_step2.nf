process REGENIE_LOG_PARSER_STEP2 {

  publishDir "${params.outdir}/logs", mode: 'copy'

  input:
    path regenie_step2_logs
    path regenie_log_parser_jar

  output:
    path "${params.project}.step2.log", emit: regenie_step2_parsed_logs

  """
  java -jar ${regenie_log_parser_jar} ${regenie_step2_logs} --output ${params.project}.step2.log
  """

}
