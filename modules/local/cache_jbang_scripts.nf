process CACHE_JBANG_SCRIPTS {

  input:
    path regenie_log_parser
    path regenie_filter

  output:
    path "RegenieLogParser.jar", emit: regenie_log_parser_jar
    path "RegenieFilter.jar", emit: regenie_filter_jar

  """
  jbang export portable -O=RegenieLogParser.jar ${regenie_log_parser}
  jbang export portable -O=RegenieFilter.jar ${regenie_filter}
  """

}
