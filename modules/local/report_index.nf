import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

process REPORT_INDEX {

  publishDir "${params.outdir}", mode: 'copy'

  input:
    val phenotypes
    path files
    path reports

  output:
    path "index.html"
    path "index_reports/*"

  script:

  """
  java -jar /opt/genomic-utils.jar gwas-report \
    ${files.join(" ")} \
    --rsid RSID \
    --gene GENE_NAME \
    --annotation GENE \
    --tab-name "Details and Phenotype" \
    --tab-links "${reports.join(",")}" \
    --names "${phenotypes.join(",")}" \
    --title "${params.project}" \
    --peak-variant-Counting-pval-threshold ${params.annotation_min_log10p} \
    --peak-pval-threshold 1.5 \
    --index ALWAYS \
    --output index.html
  """
}
