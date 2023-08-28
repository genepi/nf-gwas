import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

process REPORT_INDEX {

  publishDir "${params.outdir}", mode: 'copy'

  input:
    val phenotypes
    path reports
    path manhattan

  output:
    path "index.html"
    path "index_reports/*"

  script:

  """
  java -jar /opt/genomic-utils.jar gwas-report-index \
    --tab-name "Details and Phenotype" \
    --plots "${manhattan.join(",")}" \
    --tab-links "${reports.join(",")}" \
    --names "${phenotypes.join(",")}" \
    --title "${params.project}" \
    --output index.html
  """
}
