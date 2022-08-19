process REGENIE_LOG_PARSER_STEP2 {

  publishDir "${params.outdir}/logs", mode: 'copy'

  input:
    path regenie_step2_logs

  output:
    path "${params.project}.step2.log", emit: regenie_step2_parsed_logs

  """
  java -jar /opt/RegenieLogParser.jar ${regenie_step2_logs} --output ${params.project}.step2.log
  """

}
