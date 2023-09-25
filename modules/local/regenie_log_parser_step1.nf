process REGENIE_LOG_PARSER_STEP1 {

  publishDir "${params.pubDir}/logs", mode: 'copy'

  input:
    path regenie_step1_log

  output:
    path "${params.project}.step1.log", emit: regenie_step1_parsed_logs

  """
  java -jar /opt/RegenieLogParser.jar ${regenie_step1_log} --output ${params.project}.step1.log
  """
  }
